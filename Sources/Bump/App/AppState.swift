import Foundation
import SwiftUI
import Combine

/// Central orchestrator: wires the sensor → detection pipeline, publishes UI
/// state, and dispatches the user's mapped actions (with per-app context).
@MainActor
final class AppState: ObservableObject {
    // Live UI state
    @Published var isListening = true
    @Published var sensitivity: Double = 0.5
    @Published var lastGesture: BumpGesture?
    @Published var lastGestureTime: Date?
    @Published var gestureCounts: [BumpGesture: Int] = [:]
    /// Live waveform ring buffer — read at vsync by the UI, never published.
    let waves = WaveBuffer(count: 240)
    @Published private(set) var accelSupported = false
    @Published private(set) var accessibilityTrusted = false
    @Published private(set) var inputMonitoringTrusted = false

    // Mappings (persisted)
    @Published var global: [BumpGesture: ActionConfig] = [
        .single: ActionConfig(kind: .muteToggle),
        .double: ActionConfig(kind: .screenshotSelection),
        .triple: ActionConfig(kind: .lockScreen),
    ] { didSet { save() } }

    @Published var contexts: [AppContext] = [] { didSet { save() } }

    /// Show the expressive combo counter on rapid consecutive bumps.
    @Published var comboEnabled = true { didSet { UserDefaults.standard.set(comboEnabled, forKey: comboKey) } }
    /// Play a sound on each combo hit.
    @Published var comboSoundEnabled = true { didSet { UserDefaults.standard.set(comboSoundEnabled, forKey: comboSoundKey) } }
    /// Live combo state, rendered on the screen overlay.
    @Published private(set) var comboCount = 0
    @Published private(set) var comboToken = UUID()
    /// Active visual reactions, rendered on the screen overlay.
    @Published private(set) var reactions: [ReactionEvent] = []

    private let accelerometer = SPUAccelerometer()
    private let pipeline = DetectionPipeline()
    private let suppressor = InputSuppressor()
    private let sound = SoundPlayer()
    let soundsStore = SoundsStore()

    private var comboResetTask: Task<Void, Never>?
    private let comboWindow: TimeInterval = 2.0

    private let storeKey = "bump.store.v2"
    private let sensitivityKey = "bump.sensitivity.v1"
    private let comboKey = "bump.combo.enabled.v1"
    private let comboSoundKey = "bump.combo.sound.v1"

    init() {
        accelSupported = SPUAccelerometer.isSupported()
        load()
        applySensitivity()
        refreshPermissions()

        // Detection runs on the sensor thread (pipeline is non-actor). The waveform
        // is written straight into the lock-guarded ring buffer — NO main-actor hop,
        // so it can't starve animations. We only hop to the main actor when an
        // actual gesture fires (rare).
        var frame = 0
        accelerometer.onSample = { [pipeline, suppressor, waves, weak self] mag, time in
            if suppressor.isSuppressed(now: time) {
                pipeline.reset()
                return
            }
            let step = pipeline.process(magnitude: mag, at: time)
            frame += 1
            if frame % 12 == 0 { waves.push(step.deviation) }
            if let gesture = step.gesture {
                Task { @MainActor [weak self] in self?.emit(gesture) }
            }
        }
        suppressor.start()
        if accelSupported { accelerometer.start() }
    }

    // MARK: Permissions

    func refreshPermissions() {
        accessibilityTrusted = Permissions.isAccessibilityTrusted
        inputMonitoringTrusted = Permissions.isInputMonitoringTrusted
    }
    func requestAccessibility() {
        Permissions.promptAccessibility()
        Permissions.openAccessibilitySettings()
    }
    func requestInputMonitoring() {
        Permissions.requestInputMonitoring()
        Permissions.openInputMonitoringSettings()
    }

    // MARK: Sensitivity

    // Higher threshold = needs a firmer knock. Range ≈ 0.38 g (slider min) → 0.08 g
    // (slider max); ~0.23 g at the default mid.
    private func applySensitivity() { pipeline.threshold = 0.38 - sensitivity * 0.30 }
    func setSensitivity(_ value: Double) {
        sensitivity = value
        applySensitivity()
        UserDefaults.standard.set(value, forKey: sensitivityKey)
    }

    func toggleListening() { isListening.toggle() }

    /// Advance the combo streak and (re)start the reset timer.
    private func registerCombo() {
        comboCount += 1
        comboToken = UUID()
        if comboSoundEnabled && comboCount >= 3 { sound.play(tier: comboCount) }
        comboResetTask?.cancel()
        comboResetTask = Task { [weak self] in
            let w = self?.comboWindow ?? 2
            try? await Task.sleep(for: .seconds(w))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { self?.comboCount = 0 }
        }
    }

    // MARK: Sound file management

    func addComboSound(url: URL) {
        try? soundsStore.add(url: url)
        sound.reload()
    }
    func removeComboSound(_ name: String) {
        soundsStore.remove(name)
        sound.reload()
    }

    /// Run an action immediately (Settings "Test" buttons).
    func test(_ config: ActionConfig) {
        switch config.kind {
        case .none: break
        case .reaction: fireReaction(kind: (config.reaction ?? .screenFlash).resolved())
        case .showText: fireReaction(kind: nil, text: config.text ?? "Bump!")
        default: ActionRunner.run(config)
        }
    }

    // MARK: Visual reactions (rendered by the screen overlay)

    func fireReaction(kind: ReactionKind?, text: String? = nil) {
        // The glitch distorts a live screen grab — capture first (async), then show.
        if kind == .glitch {
            Task { @MainActor [weak self] in
                let snap = await ScreenCapture.grab()
                self?.reactions.append(ReactionEvent(kind: .glitch, text: text, snapshot: snap))
            }
        } else {
            reactions.append(ReactionEvent(kind: kind, text: text, snapshot: nil))
        }
    }
    func removeReaction(_ id: UUID) { reactions.removeAll { $0.id == id } }

    // MARK: Mapping access (used by Settings)

    func globalConfig(for gesture: BumpGesture) -> ActionConfig { global[gesture] ?? .none }
    func setGlobal(_ config: ActionConfig, for gesture: BumpGesture) { global[gesture] = config }

    func addContext(bundleID: String, name: String) {
        guard !contexts.contains(where: { $0.bundleID == bundleID }) else { return }
        contexts.append(AppContext(bundleID: bundleID, name: name))
    }
    func removeContext(_ bundleID: String) { contexts.removeAll { $0.bundleID == bundleID } }
    func setContext(_ config: ActionConfig, bundleID: String, gesture: BumpGesture) {
        guard let i = contexts.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        if config.kind == .none { contexts[i].mapping[gesture] = nil }
        else { contexts[i].mapping[gesture] = config }
    }

    /// Resolve the action for a gesture, honoring the frontmost app's context.
    private func resolve(_ gesture: BumpGesture) -> ActionConfig {
        if let bundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           let ctx = contexts.first(where: { $0.bundleID == bundle }),
           let cfg = ctx.mapping[gesture] {
            return cfg
        }
        return global[gesture] ?? .none
    }

    // MARK: Sample handling

    private func emit(_ gesture: BumpGesture) {
        guard isListening else { return }
        // Re-check suppression at emit time: a trackpad/mouse event coincident with
        // the impulse may have landed just *after* the sensor-thread check, but the
        // burst only finalizes ~0.3 s later — by now the event is recorded.
        if suppressor.isSuppressed(now: ProcessInfo.processInfo.systemUptime) { return }
        lastGesture = gesture
        lastGestureTime = Date()
        gestureCounts[gesture, default: 0] += 1

        // Snap whether a streak is already running before we extend it.
        // The first bump fires its action; subsequent bumps in the same streak
        // only advance the combo counter so the action isn't spammed.
        let inStreak = comboEnabled && comboCount >= 5
        if comboEnabled { registerCombo() }
        guard !inStreak else { return }

        let config = resolve(gesture)
        switch config.kind {
        case .none:
            break
        case .reaction:
            fireReaction(kind: (config.reaction ?? .screenFlash).resolved())
        case .showText:
            fireReaction(kind: nil, text: config.text ?? "Bump!")
        default:
            ActionRunner.run(config)
        }
    }

    // MARK: Persistence

    private struct Store: Codable {
        var global: [BumpGesture: ActionConfig]
        var contexts: [AppContext]
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode(Store.self, from: data) {
            global = decoded.global
            contexts = decoded.contexts
        }
        if defaults.object(forKey: sensitivityKey) != nil {
            sensitivity = defaults.double(forKey: sensitivityKey)
        }
        if defaults.object(forKey: comboKey) != nil {
            comboEnabled = defaults.bool(forKey: comboKey)
        }
        if defaults.object(forKey: comboSoundKey) != nil {
            comboSoundEnabled = defaults.bool(forKey: comboSoundKey)
        }
    }

    private func save() {
        let store = Store(global: global, contexts: contexts)
        if let data = try? JSONEncoder().encode(store) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}
