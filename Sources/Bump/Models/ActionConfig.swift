import Foundation

/// A fully-configured action: a kind plus any parameters it needs. This is what
/// a gesture maps to.
struct ActionConfig: Codable, Hashable {
    var kind: ActionKind = .none

    // Parameters (only the ones relevant to `kind` are used).
    var appPath: String?            // launchApp
    var script: String?             // runScript
    var scriptKind: ScriptKind?     // runScript
    var shortcutName: String?       // runShortcut
    var text: String?               // showText
    var reaction: ReactionKind?     // reaction

    init(kind: ActionKind = .none) { self.kind = kind }

    static let none = ActionConfig(kind: .none)

    /// Short human description for list rows.
    var summary: String {
        switch kind {
        case .launchApp:
            return appPath.map { "Launch \(($0 as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: ""))" } ?? kind.label
        case .runScript:
            return "Run \((scriptKind ?? .shell).label) Script"
        case .runShortcut:
            return shortcutName.map { "Run “\($0)”" } ?? kind.label
        case .showText:
            return text.map { "Show “\($0)”" } ?? kind.label
        case .reaction:
            return (reaction ?? .screenFlash).label
        default:
            return kind.label
        }
    }
}
