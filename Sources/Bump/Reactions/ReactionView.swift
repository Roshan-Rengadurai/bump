import SwiftUI

/// One full-screen visual reaction. `TimelineView(.animation)` drives a `phase`
/// 0→1 derived from wall-clock elapsed time so the Canvas re-renders every vsync
/// even inside the overlay NSWindow (where `withAnimation` doesn't tick).
struct ReactionView: View {
    let effect: ReactionKind?
    let text: String?
    var snapshot: CGImage? = nil
    let onDone: () -> Void

    @State private var startDate: Date? = nil
    @State private var particles: [Particle] = []
    @State private var bars: [GlitchBar] = []

    private let cA = Color.hex(0x89b4fa)
    private let cB = Color.hex(0xcba6f7)
    private let cC = Color.hex(0xf5c2e7)

    private struct Particle { let angle: CGFloat; let dist: CGFloat; let size: CGFloat; let color: Color }
    private struct GlitchBar { let color: Color; let yFraction: CGFloat; let jitter: CGFloat; let height: CGFloat }

    private var duration: Double {
        switch effect {
        case .shockwave:   return 0.8
        case .glitch:      return 0.55
        case .screenFlash: return 0.55
        default:           return text != nil ? 1.15 : 0.5
        }
    }

    private func easedPhase(raw: CGFloat) -> CGFloat {
        effect == .glitch ? raw : 1 - pow(1 - raw, 3)   // linear for glitch, easeOut cubic otherwise
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let raw = startDate.map { CGFloat(tl.date.timeIntervalSince($0) / duration) } ?? 0
            let phase = min(1, max(0, easedPhase(raw: raw)))
            ZStack {
                Canvas { ctx, size in draw(&ctx, size, phase: phase) }
                    .ignoresSafeArea()
                if let text { textBadge(text, phase: phase) }
            }
        }
        .onAppear {
            if effect == .shockwave { particles = Self.makeParticles(cA, cB, cC) }
            if effect == .glitch    { bars = Self.makeBars() }
            startDate = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05, execute: onDone)
        }
    }

    // MARK: Dispatch

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat) {
        switch effect {
        case .screenFlash: drawFlash(&ctx, size, phase: phase); drawEdgeGlow(&ctx, size, phase: phase)
        case .shockwave:   drawShockwave(&ctx, size, phase: phase); drawEdgeGlow(&ctx, size, phase: phase)
        case .glitch:      drawGlitch(&ctx, size, phase: phase)
        case .random, .none: break
        }
    }

    // MARK: Effects

    private func drawFlash(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat) {
        let c = CGPoint(x: size.width/2, y: size.height/2)
        let r = max(size.width, size.height) * (0.3 + 0.7 * phase)
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [.white.opacity(0.6 * (1 - phase)), cA.opacity(0.2 * (1 - phase)), .clear]),
            center: c, startRadius: 0, endRadius: r)
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: shading)
    }

    private func drawEdgeGlow(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat) {
        let pulse = sin(Double(phase) * .pi)
        guard pulse > 0.01 else { return }
        let c = CGPoint(x: size.width/2, y: size.height/2)
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(stops: [.init(color: .clear, location: 0),
                             .init(color: .clear, location: 0.62),
                             .init(color: cB.opacity(0.4 * pulse), location: 1)]),
            center: c, startRadius: 0, endRadius: max(size.width, size.height) * 0.75)
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: shading)
    }

    private func drawShockwave(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat) {
        let c = CGPoint(x: size.width/2, y: size.height/2)
        let diag = hypot(size.width, size.height)

        // central flash — fades out fast
        let flashA = max(0, 0.7 * (1 - phase * 1.6))
        if flashA > 0.01 {
            let fr: CGFloat = 240
            ctx.fill(Path(ellipseIn: CGRect(x: c.x-fr, y: c.y-fr, width: fr*2, height: fr*2)),
                     with: .radialGradient(Gradient(colors: [.white.opacity(flashA), .clear]),
                                           center: c, startRadius: 0, endRadius: fr))
        }
        // 4 staggered expanding rings
        for i in 0..<4 {
            let pr = max(0, min(1, (phase - CGFloat(i) * 0.12) / 0.88))
            guard pr > 0 else { continue }
            let d = diag * pr
            let a = 1 - pr
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x-d/2, y: c.y-d/2, width: d, height: d)),
                       with: .linearGradient(Gradient(colors: [cA.opacity(a), cB.opacity(a)]),
                                             startPoint: CGPoint(x: c.x-d/2, y: c.y-d/2),
                                             endPoint:   CGPoint(x: c.x+d/2, y: c.y+d/2)),
                       lineWidth: max(1, (1 - pr) * 8))
        }
        // outward particles — fade as phase → 1
        let pa = 1 - phase
        if pa > 0.01 {
            for p in particles {
                let x = c.x + cos(p.angle) * p.dist * phase
                let y = c.y + sin(p.angle) * p.dist * phase
                ctx.fill(Path(ellipseIn: CGRect(x: x-p.size/2, y: y-p.size/2, width: p.size, height: p.size)),
                         with: .color(p.color.opacity(Double(pa))))
            }
        }
    }

    // Real screen glitch: RGB-split + torn horizontal slices on the captured snapshot.
    // Falls back to synthetic colored bands when no capture available.
    private func drawGlitch(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat) {
        guard let cg = snapshot else { drawGlitchBands(&ctx, size, phase: phase); return }
        let img = ctx.resolve(Image(decorative: cg, scale: 1, orientation: .up))
        let full = CGRect(origin: .zero, size: size)
        let intensity = max(0, 1 - phase)
        var rng = SeededRNG(seed: UInt64(phase * 9) &* 0x9E3779B1 &+ 1)

        ctx.draw(img, in: full)   // base frame

        // Chromatic aberration: red shifted left, cyan shifted right
        let split = 16 * intensity
        if split > 0.5 {
            var r = ctx; r.blendMode = .screen
            r.addFilter(.colorMultiply(Color(red: 1, green: 0.15, blue: 0.15)))
            r.draw(img, in: full.offsetBy(dx: -split, dy: 0))
            var b = ctx; b.blendMode = .screen
            b.addFilter(.colorMultiply(Color(red: 0.15, green: 0.7, blue: 1)))
            b.draw(img, in: full.offsetBy(dx: split, dy: 0))
        }
        // Torn horizontal slices
        for _ in 0..<6 {
            let y  = rng.cgFloat(0, size.height)
            let h  = rng.cgFloat(10, 46)
            let dx = rng.cgFloat(-70, 70) * intensity
            guard abs(dx) > 0.5 else { continue }
            var s = ctx
            s.clip(to: Path(CGRect(x: 0, y: y, width: size.width, height: h)))
            s.draw(img, in: full.offsetBy(dx: dx, dy: 0))
        }
    }

    private func drawGlitchBands(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat) {
        for bar in bars {
            let rect = CGRect(x: bar.jitter * (1 - phase), y: bar.yFraction * size.height,
                              width: size.width, height: bar.height)
            var b = ctx; b.blendMode = .screen
            b.fill(Path(rect), with: .color(bar.color.opacity(0.5 * Double(1 - phase))))
        }
    }

    private func textBadge(_ text: String, phase: CGFloat) -> some View {
        let appear = min(1, phase / 0.22)
        let fade   = 1 - max(0, (phase - 0.62) / 0.38)
        return Text(text)
            .font(.system(size: 60, weight: .bold, design: .rounded))
            .foregroundStyle(LinearGradient(colors: [.white, cA], startPoint: .top, endPoint: .bottom))
            .padding(.horizontal, 40).padding(.vertical, 26)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(cA.opacity(0.5), lineWidth: 1))
            .shadow(color: cA.opacity(0.4), radius: 34)
            .shadow(color: .black.opacity(0.28), radius: 20, y: 10)
            .scaleEffect(0.8 + 0.2 * appear)
            .opacity(Double(min(appear, fade)))
    }

    private static func makeParticles(_ a: Color, _ b: Color, _ c: Color) -> [Particle] {
        let colors = [a, b, c, .white]
        return (0..<16).map { _ in
            Particle(angle: .random(in: 0...(2 * .pi)), dist: .random(in: 220...520),
                     size: .random(in: 6...16), color: colors.randomElement()!)
        }
    }
    private static func makeBars() -> [GlitchBar] {
        let palette: [Color] = [.hex(0xf38ba8), .hex(0x89dceb), .white, .hex(0xcba6f7)]
        return (0..<9).map { i in
            GlitchBar(color: palette.randomElement()!,
                      yFraction: CGFloat(i) / 9 + .random(in: -0.025...0.025),
                      jitter: .random(in: -44...44), height: .random(in: 8...18))
        }
    }
}

/// Deterministic XORShift RNG — glitch jitter stable within a step, jumps between steps.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdeadbeef : seed }
    mutating func next() -> UInt64 { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state }
    mutating func cgFloat(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        lo + (hi - lo) * CGFloat(Double(next() % 10000) / 10000.0)
    }
}
