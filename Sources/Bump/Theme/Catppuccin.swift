import SwiftUI

/// A Catppuccin flavor — the full named palette.
/// Colors from https://catppuccin.com/palette.
struct Flavor: Equatable {
    let base, mantle, crust: Color
    let surface0, surface1, surface2: Color
    let overlay0: Color
    let text, subtext0, subtext1: Color
    // Accents
    let rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender: Color

    static let latte = Flavor(
        base: .hex(0xeff1f5), mantle: .hex(0xe6e9ef), crust: .hex(0xdce0e8),
        surface0: .hex(0xccd0da), surface1: .hex(0xbcc0cc), surface2: .hex(0xacb0be),
        overlay0: .hex(0x9ca0b0),
        text: .hex(0x4c4f69), subtext0: .hex(0x6c6f85), subtext1: .hex(0x5c5f77),
        rosewater: .hex(0xdc8a78), flamingo: .hex(0xdd7878), pink: .hex(0xea76cb), mauve: .hex(0x8839ef),
        red: .hex(0xd20f39), maroon: .hex(0xe64553), peach: .hex(0xfe640b), yellow: .hex(0xdf8e1d),
        green: .hex(0x40a02b), teal: .hex(0x179299), sky: .hex(0x04a5e5), sapphire: .hex(0x209fb5),
        blue: .hex(0x1e66f5), lavender: .hex(0x7287fd))

    static let frappe = Flavor(
        base: .hex(0x303446), mantle: .hex(0x292c3c), crust: .hex(0x232634),
        surface0: .hex(0x414559), surface1: .hex(0x51576d), surface2: .hex(0x626880),
        overlay0: .hex(0x737994),
        text: .hex(0xc6d0f5), subtext0: .hex(0xa5adce), subtext1: .hex(0xb5bfe2),
        rosewater: .hex(0xf2d5cf), flamingo: .hex(0xeebebe), pink: .hex(0xf4b8e4), mauve: .hex(0xca9ee6),
        red: .hex(0xe78284), maroon: .hex(0xea999c), peach: .hex(0xef9f76), yellow: .hex(0xe5c890),
        green: .hex(0xa6d189), teal: .hex(0x81c8be), sky: .hex(0x99d1db), sapphire: .hex(0x85c1dc),
        blue: .hex(0x8caaee), lavender: .hex(0xbabbf1))

    static let macchiato = Flavor(
        base: .hex(0x24273a), mantle: .hex(0x1e2030), crust: .hex(0x181926),
        surface0: .hex(0x363a4f), surface1: .hex(0x494d64), surface2: .hex(0x5b6078),
        overlay0: .hex(0x6e738d),
        text: .hex(0xcad3f5), subtext0: .hex(0xa5adcb), subtext1: .hex(0xb8c0e0),
        rosewater: .hex(0xf4dbd6), flamingo: .hex(0xf0c6c6), pink: .hex(0xf5bde6), mauve: .hex(0xc6a0f6),
        red: .hex(0xed8796), maroon: .hex(0xee99a0), peach: .hex(0xf5a97f), yellow: .hex(0xeed49f),
        green: .hex(0xa6da95), teal: .hex(0x8bd5ca), sky: .hex(0x91d7e3), sapphire: .hex(0x7dc4e4),
        blue: .hex(0x8aadf4), lavender: .hex(0xb7bdf8))

    static let mocha = Flavor(
        base: .hex(0x1e1e2e), mantle: .hex(0x181825), crust: .hex(0x11111b),
        surface0: .hex(0x313244), surface1: .hex(0x45475a), surface2: .hex(0x585b70),
        overlay0: .hex(0x6c7086),
        text: .hex(0xcdd6f4), subtext0: .hex(0xa6adc8), subtext1: .hex(0xbac2de),
        rosewater: .hex(0xf5e0dc), flamingo: .hex(0xf2cdcd), pink: .hex(0xf5c2e7), mauve: .hex(0xcba6f7),
        red: .hex(0xf38ba8), maroon: .hex(0xeba0ac), peach: .hex(0xfab387), yellow: .hex(0xf9e2af),
        green: .hex(0xa6e3a1), teal: .hex(0x94e2d5), sky: .hex(0x89dceb), sapphire: .hex(0x74c7ec),
        blue: .hex(0x89b4fa), lavender: .hex(0xb4befe))
}

extension Color {
    static func hex(_ hex: UInt) -> Color {
        Color(.sRGB,
              red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255,
              opacity: 1)
    }
}
