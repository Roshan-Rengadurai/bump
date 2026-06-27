import SwiftUI
import AppKit

/// One active visual reaction.
struct ReactionEvent: Identifiable {
    let id = UUID()
    let kind: ReactionKind?    // nil = text-only ("Show Text")
    let text: String?
    var snapshot: CGImage?     // screen grab for the glitch effect
}

/// Owns a persistent, full-screen, click-through overlay window that renders the
/// combo counter and visual reactions on the *actual screen* (above all apps),
/// not inside the Bump window. Created once; lives for the app's lifetime.
@MainActor
final class ScreenOverlay {
    static let shared = ScreenOverlay()
    private var windows: [NSWindow] = []

    func start(state: AppState) {
        guard windows.isEmpty else { return }
        for screen in NSScreen.screens {
            let host = NSHostingView(rootView: OverlayView(state: state).frame(width: screen.frame.width, height: screen.frame.height))
            host.frame = CGRect(origin: .zero, size: screen.frame.size)

            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.isOpaque = false
            w.backgroundColor = .clear
            w.level = .screenSaver
            w.ignoresMouseEvents = true
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            w.hasShadow = false
            w.contentView = host
            w.setFrame(screen.frame, display: true)
            w.orderFrontRegardless()
            windows.append(w)
        }
    }
}

/// Renders combo + reactions full-screen. Observes `AppState`; uses SwiftUI
/// animations / `TimelineView(.animation)` (display-linked, up to 120 Hz).
struct OverlayView: View {
    @ObservedObject var state: AppState
    @State private var shake: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Visual reactions (each self-removes when its animation finishes).
            ForEach(state.reactions) { ev in
                ReactionView(effect: ev.kind, text: ev.text, snapshot: ev.snapshot) { state.removeReaction(ev.id) }
            }
            // Combo counter (only from the 3rd chained bump).
            if state.comboCount >= 3 {
                ComboBadge(count: state.comboCount, token: state.comboToken)
                    .padding(.top, 80)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .modifier(ShakeEffect(amount: shake))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state.comboCount >= 3)
        .onChange(of: state.comboToken) { _, _ in
            guard state.comboCount >= 8 else { return }   // Godlike → shake the screen
            withAnimation(.linear(duration: 0.32)) { shake += 1 }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Fast horizontal+vertical shake; each +1 of `amount` = one decaying burst.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat
    var travel: CGFloat = 14
    var shakes: CGFloat = 9
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let envelope = 1 - (amount.truncatingRemainder(dividingBy: 1))   // decay within each burst
        let dx = travel * envelope * sin(amount * .pi * shakes)
        let dy = travel * 0.55 * envelope * cos(amount * .pi * shakes * 1.27)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: dy))
    }
}
