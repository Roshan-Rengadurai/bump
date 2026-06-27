import Foundation

/// Everything a bump can do. System actions need no parameters; the advanced
/// kinds (launch, script, shortcut, text, reaction) read parameters from the
/// surrounding `ActionConfig`.
enum ActionKind: String, Codable, CaseIterable, Identifiable {
    case none
    // System
    case muteToggle
    case playPause
    case nextTrack
    case previousTrack
    case volumeUp
    case volumeDown
    case lockScreen
    case screenshotSelection
    case screenshotFull
    case copy
    case paste
    case missionControl
    case desktopLeft
    case desktopRight
    // Advanced (Pro-parity, free here)
    case launchApp
    case runScript
    case runShortcut
    case showText
    case reaction

    var id: String { rawValue }

    /// True if this kind reads extra parameters from its `ActionConfig`.
    var needsConfig: Bool {
        switch self {
        case .launchApp, .runScript, .runShortcut, .showText, .reaction: return true
        default: return false
        }
    }

    var label: String {
        switch self {
        case .none: return "Do Nothing"
        case .muteToggle: return "Mute / Unmute"
        case .playPause: return "Play / Pause"
        case .nextTrack: return "Next Track"
        case .previousTrack: return "Previous Track"
        case .volumeUp: return "Volume Up"
        case .volumeDown: return "Volume Down"
        case .lockScreen: return "Lock Screen"
        case .screenshotSelection: return "Screenshot (Selection)"
        case .screenshotFull: return "Screenshot (Full)"
        case .copy: return "Copy"
        case .paste: return "Paste"
        case .missionControl: return "Mission Control"
        case .desktopLeft: return "Desktop Left"
        case .desktopRight: return "Desktop Right"
        case .launchApp: return "Launch App…"
        case .runScript: return "Run Script…"
        case .runShortcut: return "Run Shortcut…"
        case .showText: return "Show Text…"
        case .reaction: return "Visual Reaction…"
        }
    }

    var symbol: String {
        switch self {
        case .none: return "circle.slash"
        case .muteToggle: return "speaker.slash.fill"
        case .playPause: return "playpause.fill"
        case .nextTrack: return "forward.fill"
        case .previousTrack: return "backward.fill"
        case .volumeUp: return "speaker.wave.3.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .lockScreen: return "lock.fill"
        case .screenshotSelection: return "macwindow.on.rectangle"
        case .screenshotFull: return "camera.viewfinder"
        case .copy: return "doc.on.doc"
        case .paste: return "doc.on.clipboard"
        case .missionControl: return "rectangle.3.group"
        case .desktopLeft: return "arrow.left.to.line"
        case .desktopRight: return "arrow.right.to.line"
        case .launchApp: return "app.dashed"
        case .runScript: return "terminal"
        case .runShortcut: return "square.stack.3d.up"
        case .showText: return "textformat"
        case .reaction: return "sparkles"
        }
    }
}

/// Which interpreter runs a `runScript` action.
enum ScriptKind: String, Codable, CaseIterable, Identifiable {
    case shell
    case appleScript

    var id: String { rawValue }
    var label: String { self == .shell ? "Shell (zsh)" : "AppleScript" }
}
