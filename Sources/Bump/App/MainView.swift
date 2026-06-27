import SwiftUI
import AppKit

enum AppSection: String, CaseIterable, Identifiable {
    case home, bumps, perApp, appearance, about
    var id: String { rawValue }
    var label: String {
        switch self {
        case .home: return "Home"
        case .bumps: return "Bumps"
        case .perApp: return "Per-App"
        case .appearance: return "Appearance"
        case .about: return "About"
        }
    }
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .bumps: return "hand.tap.fill"
        case .perApp: return "square.grid.2x2.fill"
        case .appearance: return "paintpalette.fill"
        case .about: return "info.circle.fill"
        }
    }
}

/// The full windowed app: themed sidebar + section detail.
struct MainView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.palette) private var pal
    @State private var section: AppSection = .home

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(pal.surface0)
            ScrollView {
                Group {
                    switch section {
                    case .home: HomeSection()
                    case .bumps: BumpsSection()
                    case .perApp: PerAppSection()
                    case .appearance: AppearanceSection()
                    case .about: AboutSection()
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(pal.base)
        }
        .frame(minWidth: 880, minHeight: 600)
        .background(pal.base)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "hand.tap.fill").font(.title2).foregroundStyle(.tint)
                Text("Bump").font(.title2.weight(.bold)).foregroundStyle(pal.text)
            }
            .padding(.horizontal, 12).padding(.top, 18).padding(.bottom, 16)

            ForEach(AppSection.allCases) { s in
                SidebarItem(section: s, selected: section == s) {
                    withAnimation(.easeOut(duration: 0.15)) { section = s }
                }
            }
            Spacer()
            statusFooter
        }
        .frame(width: 212)
        .background(pal.mantle)
    }

    private var statusFooter: some View {
        HStack(spacing: 8) {
            Circle().fill(state.isListening ? pal.green : pal.overlay0).frame(width: 8, height: 8)
            Text(state.isListening ? "Listening" : "Paused").font(.caption).foregroundStyle(pal.subtext0)
            Spacer()
            Button { state.toggleListening() } label: {
                Image(systemName: state.isListening ? "pause.fill" : "play.fill")
                    .foregroundStyle(pal.subtext1)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}

private struct SidebarItem: View {
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent
    let section: AppSection
    let selected: Bool
    let action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbol).frame(width: 20).foregroundStyle(selected ? accent : pal.subtext0)
                Text(section.label).foregroundStyle(selected ? pal.text : pal.subtext1)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selected ? accent.opacity(0.14) : (hover ? pal.surface0.opacity(0.5) : .clear),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(alignment: .leading) {
                if selected {
                    Capsule().fill(accent).frame(width: 3, height: 18).padding(.leading, 2)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hover = $0 }
    }
}

// MARK: - Section title

private struct SectionTitle: View {
    @Environment(\.palette) private var pal
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(pal.text)
            Text(subtitle).font(.callout).foregroundStyle(pal.subtext0)
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Home

private struct HomeSection: View {
    @EnvironmentObject var state: AppState
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "Home", subtitle: "Live status and a place to test your knocks.")

            if !state.accessibilityTrusted || !state.inputMonitoringTrusted {
                permissionBanner
            }

            Card {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        SectionLabel(text: "Live Trace")
                        Spacer()
                        StatusPill(text: state.accelSupported ? "Sensor ready" : "No sensor",
                                   color: state.accelSupported ? pal.green : pal.peach)
                    }
                    WaveformView(buffer: state.waves).frame(height: 160)
                    HStack(spacing: 10) {
                        Image(systemName: "tortoise.fill").foregroundStyle(pal.subtext0)
                        Slider(value: Binding(get: { state.sensitivity }, set: { state.setSensitivity($0) }), in: 0...1)
                        Image(systemName: "hare.fill").foregroundStyle(pal.subtext0)
                    }
                }
            }

            HStack(spacing: 16) {
                ForEach(BumpGesture.allCases) { g in
                    Card {
                        VStack(spacing: 6) {
                            Image(systemName: g.symbol).font(.title2).foregroundStyle(accent)
                            Text("\(state.gestureCounts[g] ?? 0)").font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit()).foregroundStyle(pal.text)
                            Text(g.label).font(.caption).foregroundStyle(pal.subtext0)
                        }.frame(maxWidth: .infinity)
                    }
                }
            }

        }
    }

    private var permissionBanner: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(pal.peach).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Permissions needed").font(.headline).foregroundStyle(pal.text)
                    Text("Bump needs Input Monitoring + Accessibility to detect and act.").font(.caption).foregroundStyle(pal.subtext0)
                }
                Spacer()
                if !state.inputMonitoringTrusted { GhostButton(title: "Input…") { state.requestInputMonitoring() } }
                if !state.accessibilityTrusted { GhostButton(title: "Accessibility…") { state.requestAccessibility() } }
            }
        }
    }
}

// MARK: - Bumps (global mappings)

private struct BumpsSection: View {
    @EnvironmentObject var state: AppState
    @Environment(\.palette) private var pal

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Bumps", subtitle: "Assign an action to each knock. Applies everywhere unless a per-app override exists.")
            ForEach(BumpGesture.allCases) { g in
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(g.label, systemImage: g.symbol).font(.headline).foregroundStyle(pal.text)
                        ActionEditor(
                            config: Binding(get: { state.globalConfig(for: g) },
                                            set: { state.setGlobal($0, for: g) }),
                            onTest: { state.test($0) })
                    }
                }
            }
        }
    }
}

// MARK: - Per-App

private struct PerAppSection: View {
    @EnvironmentObject var state: AppState
    @Environment(\.palette) private var pal

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionTitle(title: "Per-App", subtitle: "Override your bumps when a specific app is in front.")
                Spacer()
                AccentButton(title: "Add App", systemImage: "plus") { addApp() }
            }
            if state.contexts.isEmpty {
                Card {
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2").font(.largeTitle).foregroundStyle(pal.overlay0)
                        Text("No app overrides yet").font(.headline).foregroundStyle(pal.text)
                        Text("Add an app to give it its own knock actions.").font(.caption).foregroundStyle(pal.subtext0)
                    }.frame(maxWidth: .infinity).padding(.vertical, 20)
                }
            } else {
                ForEach(state.contexts) { ctx in contextCard(ctx) }
            }
        }
    }

    private func contextCard(_ ctx: AppContext) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(ctx.name, systemImage: "app.fill").font(.headline).foregroundStyle(pal.text)
                    Spacer()
                    Button(role: .destructive) { state.removeContext(ctx.bundleID) } label: {
                        Image(systemName: "trash").foregroundStyle(pal.red)
                    }.buttonStyle(.plain)
                }
                ForEach(BumpGesture.allCases) { g in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(g.label).font(.caption).foregroundStyle(pal.subtext0)
                        ActionEditor(
                            config: Binding(get: { ctx.mapping[g] ?? .none },
                                            set: { state.setContext($0, bundleID: ctx.bundleID, gesture: g) }),
                            onTest: { state.test($0) })
                    }
                }
            }
        }
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url,
              let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else { return }
        let name = (url.lastPathComponent as NSString).replacingOccurrences(of: ".app", with: "")
        state.addContext(bundleID: id, name: name)
    }
}

// MARK: - Appearance

private struct AppearanceSection: View {
    @EnvironmentObject var state: AppState
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "Appearance", subtitle: "Theme Bump with Catppuccin and tune the flair.")
            Card { FlavorPicker() }
            Card { AccentPicker() }
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $state.comboEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Combo effects").font(.headline).foregroundStyle(pal.text)
                            Text("Animated streak counter on rapid knocks.").font(.caption).foregroundStyle(pal.subtext0)
                        }
                    }.toggleStyle(.switch).tint(accent)
                    Divider().overlay(pal.surface1)
                    Toggle(isOn: $state.comboSoundEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Combo sound").font(.headline).foregroundStyle(pal.text)
                            Text("Play a sound on each combo hit. Pitch rises with streak length.")
                                .font(.caption).foregroundStyle(pal.subtext0)
                        }
                    }.toggleStyle(.switch).tint(accent).disabled(!state.comboEnabled)

                    if state.comboEnabled && state.comboSoundEnabled {
                        Divider().overlay(pal.surface1)
                        ComboSoundsEditor(store: state.soundsStore)
                    }
                }
            }
        }
    }
}

private struct ComboSoundsEditor: View {
    @ObservedObject var store: SoundsStore
    @EnvironmentObject var state: AppState
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sound clips").font(.subheadline.weight(.medium)).foregroundStyle(pal.subtext1)
                Spacer()
                Button {
                    pickSound()
                } label: {
                    Label("Add Sound…", systemImage: "plus")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }

            if store.files.isEmpty {
                Text("No clips yet — tap + to add .wav/.mp3/.m4a files.")
                    .font(.caption).foregroundStyle(pal.overlay0)
                    .padding(.vertical, 4)
            } else {
                ForEach(store.files, id: \.self) { name in
                    HStack {
                        Image(systemName: "waveform").foregroundStyle(pal.subtext0).font(.caption)
                        Text(name).font(.caption).foregroundStyle(pal.text).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Button {
                            state.removeComboSound(name)
                        } label: {
                            Image(systemName: "trash").foregroundStyle(pal.red).font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func pickSound() {
        let panel = NSOpenPanel()
        panel.title = "Choose a sound clip"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]
        guard panel.runModal() == .OK else { return }
        for url in panel.urls { state.addComboSound(url: url) }
    }
}

// MARK: - About

private struct AboutSection: View {
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "About", subtitle: "")
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill").font(.largeTitle).foregroundStyle(accent)
                        VStack(alignment: .leading) {
                            Text("Bump").font(.title.weight(.bold)).foregroundStyle(pal.text)
                            Text("Free, open-source tap-to-control for your Mac.").font(.callout).foregroundStyle(pal.subtext0)
                        }
                    }
                    Divider().overlay(pal.surface1)
                    Text("Knock your laptop’s body to mute, lock, screenshot, run scripts, and more. A free alternative to commercial tap apps — every feature unlocked.")
                        .font(.callout).foregroundStyle(pal.subtext1).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
