import Foundation

/// Visual flourishes drawn over the whole screen when a bump fires.
enum ReactionKind: String, Codable, CaseIterable, Identifiable {
    case screenFlash
    case shockwave
    case glitch
    case random

    var id: String { rawValue }

    var label: String {
        switch self {
        case .screenFlash: return "Screen Flash"
        case .shockwave: return "Shockwave"
        case .glitch: return "Glitch"
        case .random: return "Random"
        }
    }

    var symbol: String {
        switch self {
        case .screenFlash: return "bolt.fill"
        case .shockwave: return "circle.circle"
        case .glitch: return "waveform.path.ecg"
        case .random: return "dice"
        }
    }

    /// Concrete kinds (everything except `.random`).
    static var concrete: [ReactionKind] { [.screenFlash, .shockwave, .glitch] }

    /// Resolve `.random` to a concrete kind.
    func resolved() -> ReactionKind {
        self == .random ? (ReactionKind.concrete.randomElement() ?? .screenFlash) : self
    }
}
