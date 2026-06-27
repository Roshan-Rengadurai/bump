import SwiftUI

/// First-run onboarding: welcome → permissions → knock test → look → done.
struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent
    @Binding var onboarded: Bool

    @State private var step = 0
    private let lastStep = 4
    private let ticker = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ProgressDots(count: lastStep + 1, current: step)
                .padding(.top, 26)

            Group {
                switch step {
                case 0: welcome
                case 1: permissions
                case 2: knockTest
                case 3: look
                default: done
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(pal.base)
        .onReceive(ticker) { _ in state.refreshPermissions() }
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(accent.opacity(0.15)).frame(width: 130, height: 130)
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("Bump").font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(pal.text)
            Text("Control your Mac with a knock.")
                .font(.title3).foregroundStyle(pal.subtext0)
            Text("Tap your laptop’s body — once, twice, or three times — to fire any action. Free and open source.")
                .font(.callout).foregroundStyle(pal.subtext0)
                .multilineTextAlignment(.center).frame(maxWidth: 420)
            Spacer()
        }.padding(40)
    }

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader("Grant two permissions",
                       "Bump reads the built-in motion sensor and runs your actions. Nothing leaves your Mac.")
            PermissionRow(
                title: "Input Monitoring",
                detail: "Lets Bump read the accelerometer and ignore taps while you type or use the trackpad.",
                symbol: "dot.radiowaves.left.and.right",
                granted: state.inputMonitoringTrusted,
                action: { state.requestInputMonitoring() })
            PermissionRow(
                title: "Accessibility",
                detail: "Lets Bump trigger actions like mute, lock, and media keys.",
                symbol: "lock.shield",
                granted: state.accessibilityTrusted,
                action: { state.requestAccessibility() })
            Text("After enabling each in System Settings, come back here — the checkmarks update automatically.")
                .font(.caption).foregroundStyle(pal.subtext0)
            Spacer()
        }.padding(40)
    }

    private var knockTest: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader("Give it a knock", "Tap your laptop body and watch the trace jump. Tune the sensitivity so your knocks land.")
            Card {
                VStack(spacing: 14) {
                    WaveformView(buffer: state.waves).frame(height: 150)
                    HStack {
                        Image(systemName: "tortoise.fill").foregroundStyle(pal.subtext0)
                        Slider(value: Binding(get: { state.sensitivity },
                                              set: { state.setSensitivity($0) }), in: 0...1)
                        Image(systemName: "hare.fill").foregroundStyle(pal.subtext0)
                    }
                    HStack(spacing: 10) {
                        ForEach(BumpGesture.allCases) { g in
                            countChip(g)
                        }
                    }
                }
            }
            if !state.accelSupported {
                Label("No built-in accelerometer found on this Mac.", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout).foregroundStyle(pal.peach)
            }
            Spacer()
        }.padding(40)
    }

    private var look: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader("Make it yours", "Pick a Catppuccin flavor and accent. Change it anytime in Appearance.")
            FlavorPicker()
            AccentPicker()
            Toggle(isOn: $state.comboEnabled) {
                Text("Show combo effects on rapid knocks").foregroundStyle(pal.text)
            }
            .toggleStyle(.switch).tint(accent)
            Spacer()
        }.padding(40)
    }

    private var done: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(pal.green.opacity(0.15)).frame(width: 120, height: 120)
                Image(systemName: "checkmark").font(.system(size: 50, weight: .bold)).foregroundStyle(pal.green)
            }
            Text("You’re all set").font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(pal.text)
            Text("Bump lives in your menu bar and dock. Knock away.")
                .font(.callout).foregroundStyle(pal.subtext0).multilineTextAlignment(.center)
            Spacer()
        }.padding(40)
    }

    // MARK: Bits

    private func stepHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(pal.text)
            Text(subtitle).font(.callout).foregroundStyle(pal.subtext0).frame(maxWidth: 460, alignment: .leading)
        }
    }

    private func countChip(_ g: BumpGesture) -> some View {
        VStack(spacing: 4) {
            Text("\(state.gestureCounts[g] ?? 0)").font(.title2.weight(.bold).monospacedDigit()).foregroundStyle(accent)
            Text(g.label.replacingOccurrences(of: " Bump", with: "")).font(.caption2).foregroundStyle(pal.subtext0)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(pal.surface0.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private var controls: some View {
        HStack {
            if step > 0 {
                GhostButton(title: "Back") { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step -= 1 } }
            }
            Spacer()
            AccentButton(title: step == lastStep ? "Start knocking" : "Continue",
                         systemImage: step == lastStep ? "checkmark" : "arrow.right") {
                if step == lastStep { onboarded = true }
                else { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step += 1 } }
            }
        }
        .padding(.horizontal, 40).padding(.vertical, 22)
        .background(pal.mantle)
    }
}

/// Row dots showing onboarding progress.
private struct ProgressDots: View {
    @Environment(\.bumpAccent) private var accent
    @Environment(\.palette) private var pal
    let count: Int
    let current: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule().fill(i == current ? accent : pal.surface1)
                    .frame(width: i == current ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }
}

/// One permission row with live status + grant button.
private struct PermissionRow: View {
    @Environment(\.palette) private var pal
    let title: String
    let detail: String
    let symbol: String
    let granted: Bool
    let action: () -> Void
    var body: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.title2).foregroundStyle(granted ? pal.green : pal.subtext0).frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(pal.text)
                    Text(detail).font(.caption).foregroundStyle(pal.subtext0).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if granted {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.semibold)).foregroundStyle(pal.green).labelStyle(.titleAndIcon)
                } else {
                    GhostButton(title: "Grant…", action: action)
                }
            }
        }
    }
}
