import SwiftUI
import Combine

/// User's flavor choice. `auto` follows the system appearance (Latte / Mocha).
enum FlavorChoice: String, CaseIterable, Identifiable {
    case auto, latte, frappe, macchiato, mocha
    var id: String { rawValue }
    var label: String {
        switch self {
        case .auto: return "Auto"
        case .latte: return "Latte"
        case .frappe: return "Frappé"
        case .macchiato: return "Macchiato"
        case .mocha: return "Mocha"
        }
    }
    var subtitle: String {
        switch self {
        case .auto: return "Match system"
        case .latte: return "Light"
        case .frappe: return "Soft dark"
        case .macchiato: return "Dark"
        case .mocha: return "Darkest"
        }
    }
    /// A representative swatch (base + accent) for the picker, independent of system.
    var previewFlavor: Flavor {
        switch self {
        case .auto, .mocha: return .mocha
        case .latte: return .latte
        case .frappe: return .frappe
        case .macchiato: return .macchiato
        }
    }
}

/// Accent color choice, resolved against the active flavor.
enum Accent: String, CaseIterable, Identifiable {
    case mauve, blue, lavender, sapphire, teal, green, yellow, peach, red, pink
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    func color(in f: Flavor) -> Color {
        switch self {
        case .mauve: return f.mauve
        case .blue: return f.blue
        case .lavender: return f.lavender
        case .sapphire: return f.sapphire
        case .teal: return f.teal
        case .green: return f.green
        case .yellow: return f.yellow
        case .peach: return f.peach
        case .red: return f.red
        case .pink: return f.pink
        }
    }
}

/// Holds and persists the user's theme choices.
@MainActor
final class ThemeManager: ObservableObject {
    @Published var flavor: FlavorChoice { didSet { save() } }
    @Published var accent: Accent { didSet { save() } }

    private let flavorKey = "bump.theme.flavor.v1"
    private let accentKey = "bump.theme.accent.v1"

    init() {
        let d = UserDefaults.standard
        flavor = FlavorChoice(rawValue: d.string(forKey: flavorKey) ?? "") ?? .auto
        accent = Accent(rawValue: d.string(forKey: accentKey) ?? "") ?? .mauve
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(flavor.rawValue, forKey: flavorKey)
        d.set(accent.rawValue, forKey: accentKey)
    }

    /// Resolve the concrete flavor for the current system appearance.
    func resolved(_ scheme: ColorScheme) -> Flavor {
        switch flavor {
        case .auto: return scheme == .dark ? .mocha : .latte
        case .latte: return .latte
        case .frappe: return .frappe
        case .macchiato: return .macchiato
        case .mocha: return .mocha
        }
    }

    func accentColor(_ scheme: ColorScheme) -> Color { accent.color(in: resolved(scheme)) }

    /// Forcing a specific flavor also forces its light/dark appearance.
    var preferredScheme: ColorScheme? {
        switch flavor {
        case .auto: return nil
        case .latte: return .light
        case .frappe, .macchiato, .mocha: return .dark
        }
    }
}

// MARK: - Environment plumbing

private struct PaletteKey: EnvironmentKey { static let defaultValue: Flavor = .mocha }
private struct AccentKey: EnvironmentKey { static let defaultValue: Color = Flavor.mocha.mauve }

extension EnvironmentValues {
    var palette: Flavor {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
    var bumpAccent: Color {
        get { self[AccentKey.self] }
        set { self[AccentKey.self] = newValue }
    }
}
