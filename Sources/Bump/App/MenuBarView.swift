import SwiftUI

/// The dropdown shown from the menu-bar icon — a compact companion to the window.
struct MenuBarView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openWindow) private var openWindow

    private var pal: Flavor { theme.resolved(scheme) }
    private var accent: Color { theme.accentColor(scheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.tap.fill").foregroundStyle(accent)
                Text("Bump").font(.headline).foregroundStyle(pal.text)
                Spacer()
                Circle().fill(state.isListening ? pal.green : pal.overlay0).frame(width: 8, height: 8)
            }

            Divider()

            if !state.accelSupported {
                Label("No accelerometer found", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(pal.peach)
            }
            if !state.accessibilityTrusted || !state.inputMonitoringTrusted {
                Label("Permissions needed — open Bump", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(pal.peach)
            }

            HStack {
                if let g = state.lastGesture {
                    Image(systemName: g.symbol).foregroundStyle(accent)
                    Text(g.label).foregroundStyle(pal.text)
                } else {
                    Image(systemName: "hand.tap").foregroundStyle(pal.subtext0)
                    Text("Knock to test").foregroundStyle(pal.subtext0)
                }
                Spacer()
            }.font(.callout)

            VStack(alignment: .leading, spacing: 4) {
                Text("Sensitivity").font(.caption).foregroundStyle(pal.subtext0)
                Slider(value: Binding(get: { state.sensitivity }, set: { state.setSensitivity($0) }), in: 0...1)
                    .tint(accent)
            }

            Divider()

            row("Open Bump", "macwindow") {
                NSApp.setActivationPolicy(.regular)   // restore Dock icon
                openWindow(id: WindowID.main)
                NSApp.activate(ignoringOtherApps: true)
            }
            row(state.isListening ? "Pause Detection" : "Resume Detection",
                state.isListening ? "pause.circle" : "play.circle") { state.toggleListening() }
            row("Quit Bump", "power") { NSApp.terminate(nil) }
        }
        .padding(14)
        .frame(width: 264)
        .background(pal.base)
    }

    private func row(_ title: String, _ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).foregroundStyle(pal.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
