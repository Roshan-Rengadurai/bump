import SwiftUI

/// Catppuccin flavor picker — swatch cards for Auto / Latte / Frappé / Macchiato / Mocha.
struct FlavorPicker: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Flavor")
            HStack(spacing: 10) {
                ForEach(FlavorChoice.allCases) { choice in
                    let f = choice.previewFlavor
                    let selected = theme.flavor == choice
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { theme.flavor = choice }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(f.base)
                                HStack(spacing: 4) {
                                    Circle().fill(f.mauve).frame(width: 9, height: 9)
                                    Circle().fill(f.blue).frame(width: 9, height: 9)
                                    Circle().fill(f.green).frame(width: 9, height: 9)
                                }
                            }
                            .frame(height: 46)
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(selected ? accent : pal.surface1, lineWidth: selected ? 2 : 1))
                            Text(choice.label).font(.caption.weight(selected ? .bold : .regular))
                                .foregroundStyle(selected ? pal.text : pal.subtext0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Accent color picker — a row of dots.
struct AccentPicker: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.palette) private var pal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Accent")
            HStack(spacing: 10) {
                ForEach(Accent.allCases) { a in
                    let c = a.color(in: pal)
                    let selected = theme.accent == a
                    Button {
                        withAnimation(.spring(response: 0.3)) { theme.accent = a }
                    } label: {
                        Circle().fill(c)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().strokeBorder(pal.text.opacity(selected ? 0.9 : 0), lineWidth: 2).padding(-3))
                            .overlay(Image(systemName: "checkmark").font(.system(size: 11, weight: .black))
                                .foregroundStyle(pal.crust).opacity(selected ? 1 : 0))
                    }
                    .buttonStyle(.plain)
                    .help(a.label)
                }
            }
        }
    }
}
