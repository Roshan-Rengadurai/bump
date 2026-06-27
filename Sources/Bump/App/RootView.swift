import SwiftUI
import AppKit

/// Wraps the app content with the resolved Catppuccin palette + accent and gates
/// first-run onboarding.
struct RootView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) private var scheme
    @AppStorage("bump.onboarded.v1") private var onboarded = false

    var body: some View {
        let pal = theme.resolved(scheme)
        let acc = theme.accentColor(scheme)
        Group {
            if onboarded {
                MainView()
            } else {
                OnboardingView(onboarded: $onboarded)
            }
        }
        .environment(\.palette, pal)
        .environment(\.bumpAccent, acc)
        .tint(acc)
        .preferredColorScheme(theme.preferredScheme)
        .onAppear {
            state.refreshPermissions()
            ScreenOverlay.shared.start(state: state)   // combo + reactions render on the screen overlay
        }
        // Closing the main window hides Bump from the Dock; it keeps running in the
        // menu bar. Reopening (menu → Open Bump) restores the Dock icon.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            if (note.object as? NSWindow)?.title == "Bump" {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
