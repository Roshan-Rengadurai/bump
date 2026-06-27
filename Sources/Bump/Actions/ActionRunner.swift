import Foundation
import AppKit

/// Performs the non-visual part of a `BumpAction`. System actions route through
/// synthetic events (Accessibility permission). Reactions and Show Text are
/// handled by `AppState` via `ReactionPresenter` because they touch the UI.
enum ActionRunner {
    static func run(_ config: ActionConfig) {
        switch config.kind {
        case .none, .reaction, .showText:
            break   // .reaction / .showText handled by the presenter

        // System — synthetic events
        case .muteToggle:         EventPoster.postMediaKey(.mute)
        case .playPause:          EventPoster.postMediaKey(.play)
        case .nextTrack:          EventPoster.postMediaKey(.next)
        case .previousTrack:      EventPoster.postMediaKey(.previous)
        case .volumeUp:           EventPoster.postMediaKey(.soundUp)
        case .volumeDown:         EventPoster.postMediaKey(.soundDown)
        case .lockScreen:         EventPoster.postKey(.q, flags: [.maskCommand, .maskControl])
        case .screenshotSelection:EventPoster.postKey(.four, flags: [.maskCommand, .maskShift])
        case .screenshotFull:     EventPoster.postKey(.three, flags: [.maskCommand, .maskShift])
        case .copy:               EventPoster.postKey(.c, flags: .maskCommand)
        case .paste:              EventPoster.postKey(.v, flags: .maskCommand)
        case .missionControl:     EventPoster.postKey(.up, flags: .maskControl)
        case .desktopLeft:        EventPoster.postKey(.left, flags: .maskControl)
        case .desktopRight:       EventPoster.postKey(.right, flags: .maskControl)

        // Advanced
        case .launchApp:          launchApp(config.appPath)
        case .runScript:          runScript(config.script, kind: config.scriptKind ?? .shell)
        case .runShortcut:        runShortcut(config.shortcutName)
        }
    }

    private static func launchApp(_ path: String?) {
        guard let path, !path.isEmpty else { return }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    private static func runScript(_ script: String?, kind: ScriptKind) {
        guard let script, !script.isEmpty else { return }
        switch kind {
        case .shell:
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", script]
            try? process.run()
        case .appleScript:
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&error)
            }
        }
    }

    private static func runShortcut(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        try? process.run()
    }
}
