import SwiftUI

/// Live waveform of impulse deviation. Renders inside `TimelineView(.animation)`,
/// so the Canvas redraws once per display frame (vsync) reading the lock-guarded
/// ring buffer — smooth and fully decoupled from the ~60 Hz data stream.
struct WaveformView: View {
    @Environment(\.palette) private var pal
    @Environment(\.bumpAccent) private var accent
    let buffer: WaveBuffer
    /// Full-scale value (g) mapped to the top of the view.
    var fullScale: Double = 0.35

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { ctx, size in draw(ctx, size) }
        }
        .background(pal.crust.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(pal.surface1.opacity(0.45), lineWidth: 1))
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        let samples = buffer.snapshot()
        let mid = size.height / 2

        var baseline = Path()
        baseline.move(to: CGPoint(x: 0, y: mid))
        baseline.addLine(to: CGPoint(x: size.width, y: mid))
        ctx.stroke(baseline, with: .color(pal.overlay0.opacity(0.25)), lineWidth: 1)

        guard samples.count > 1 else { return }
        let step = size.width / CGFloat(samples.count - 1)
        let scale = mid / CGFloat(fullScale)

        func point(_ i: Int, top: Bool) -> CGPoint {
            let amp = min(CGFloat(max(samples[i], 0)) * scale, mid)
            return CGPoint(x: CGFloat(i) * step, y: top ? mid - amp : mid + amp)
        }

        // soft mirrored fill
        var fill = Path()
        fill.move(to: point(0, top: true))
        for i in 1..<samples.count { fill.addLine(to: point(i, top: true)) }
        for i in stride(from: samples.count - 1, through: 0, by: -1) { fill.addLine(to: point(i, top: false)) }
        fill.closeSubpath()
        ctx.fill(fill, with: .linearGradient(
            Gradient(colors: [accent.opacity(0.30), accent.opacity(0.04)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        // crisp top line (subtle glow, not blown out)
        var line = Path()
        line.move(to: point(0, top: true))
        for i in 1..<samples.count { line.addLine(to: point(i, top: true)) }
        var glow = ctx
        glow.addFilter(.shadow(color: accent.opacity(0.35), radius: 3))
        glow.stroke(line, with: .color(accent), lineWidth: 1.75)
    }
}
