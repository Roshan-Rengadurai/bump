import SwiftUI
import AppKit

@main
struct BumpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        Window("Bump", id: WindowID.main) {
            RootView()
                .environmentObject(state)
                .environmentObject(theme)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 960, height: 680)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(state)
                .environmentObject(theme)
        } label: {
            Image(systemName: state.isListening ? "hand.tap.fill" : "hand.tap")
        }
        .menuBarExtraStyle(.window)
    }
}

enum WindowID {
    static let main = "main"
}

/// Full app: shows in the Dock with a main window, plus a menu-bar companion.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    /// Keep running (in the menu bar) after the window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    /// Re-open the main window when the dock icon is clicked with no windows.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { for w in sender.windows where w.canBecomeMain { w.makeKeyAndOrderFront(nil) } }
        return true
    }
}
