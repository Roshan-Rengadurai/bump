import SwiftUI

/// Expressive floating combo counter (Knock-style). Tier color + word escalate
/// with the streak; each hit pops with a spring, glow, ring, and a quick wiggle.
/// Driven by `count` + `token` (a fresh token on each hit retriggers the pop).
struct ComboBadge: View {
    let count: Int
    let token: UUID

    @State private var pop: CGFloat = 0.85
    @State private var ringScale: CGFloat = 0.7
    @State private var ringOpacity: Double = 0

    private var tier: (color: Color, word: String) {
        switch count {
        case 0...1: return (.hex(0xa6e3a1), "Bump")
        case 2:     return (.hex(0x94e2d5), "Nice")
        case 3:     return (.hex(0x89b4fa), "Combo")
        case 4:     return (.hex(0xf9e2af), "Hot")
        case 5:     return (.hex(0xfab387), "On Fire")
        case 6...7: return (.hex(0xf38ba8), "Unstoppable")
        default:    return (.hex(0xcba6f7), "Godlike")
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // streak count with a soft burst ring
            ZStack {
                Circle()
                    .stroke(tier.color.opacity(0.5), lineWidth: 3)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .frame(width: 64, height: 64)
                Text("\(count)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(tier.color)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 1) {
                Text(tier.word)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("combo")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(
            LinearGradient(colors: [tier.color, tier.color.opacity(0.35)],
                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
        .shadow(color: tier.color.opacity(0.35), radius: 22)
        .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
        .scaleEffect(pop)
        .onAppear { hit() }
        .onChange(of: token) { _, _ in hit() }
    }

    private func hit() {
        pop = 0.92
        withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) { pop = 1 }
        ringScale = 0.7; ringOpacity = 0.85
        withAnimation(.easeOut(duration: 0.6)) { ringScale = 1.9; ringOpacity = 0 }
    }
}
