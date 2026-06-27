import SwiftUI

/// A rounded surface card on `surface0`, used to group content.
struct Card<Content: View>: View {
    @Environment(\.palette) private var pal
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(pal.surface0.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(pal.surface1.opacity(0.5), lineWidth: 1))
    }
}

/// Small section label (uppercase, subtext color).
struct SectionLabel: View {
    @Environment(\.palette) private var pal
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(pal.subtext0)
    }
}

/// Filled accent button.
struct AccentButton: View {
    @Environment(\.bumpAccent) private var accent
    @Environment(\.palette) private var pal
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .foregroundStyle(pal.crust)
            .background(accent.opacity(hovering ? 0.85 : 1), in: Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Subtle bordered button on a surface.
struct GhostButton: View {
    @Environment(\.palette) private var pal
    let title: String
    var systemImage: String? = nil
    var action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .foregroundStyle(pal.text)
            .background(pal.surface1.opacity(hovering ? 0.9 : 0.5), in: Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// A colored status dot + label pill.
struct StatusPill: View {
    @Environment(\.palette) private var pal
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption.weight(.medium)).foregroundStyle(pal.subtext1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(pal.surface0.opacity(0.6), in: Capsule())
    }
}
