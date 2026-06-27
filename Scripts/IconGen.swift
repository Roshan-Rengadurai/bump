// Renders the Bump app icon (1024×1024 PNG) with AppKit/CoreGraphics.
// Usage: swift Scripts/IconGen.swift <output.png>
import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let S: CGFloat = 1024
let cs = CGColorSpaceCreateDeviceRGB()
func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r/255), CGFloat(g/255), CGFloat(b/255), CGFloat(a)])!
}
func white(_ a: Double) -> CGColor { CGColor(colorSpace: cs, components: [1, 1, 1, CGFloat(a)])! }

/// Tint a (template) symbol image solid white.
func tinted(_ image: NSImage, _ color: NSColor) -> NSImage {
    let img = NSImage(size: image.size)
    img.lockFocus()
    color.set()
    let r = NSRect(origin: .zero, size: image.size)
    image.draw(in: r)
    r.fill(using: .sourceAtop)
    img.unlockFocus()
    return img
}

let canvas = NSImage(size: NSSize(width: S, height: S))
canvas.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Rounded-rect (squircle-ish) mask.
let clip = CGPath(roundedRect: CGRect(x: 0, y: 0, width: S, height: S),
                  cornerWidth: 228, cornerHeight: 228, transform: nil)
ctx.addPath(clip); ctx.clip()

// Diagonal Catppuccin gradient (mauve → blue), richer/deeper for contrast.
let grad = CGGradient(colorsSpace: cs,
                      colors: [rgb(180, 130, 240), rgb(120, 150, 246), rgb(90, 120, 235)] as CFArray,
                      locations: [0, 0.55, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

// Soft top highlight.
let glow = CGGradient(colorsSpace: cs, colors: [white(0.22), white(0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: S*0.5, y: S*0.76), startRadius: 0,
                       endCenter: CGPoint(x: S*0.5, y: S*0.76), endRadius: S*0.6, options: [])

// Subtle depth vignette at the bottom corner.
let vign = CGGradient(colorsSpace: cs, colors: [rgb(40, 50, 110, 0), rgb(40, 50, 110, 0.28)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(vign, startCenter: CGPoint(x: S, y: 0), startRadius: S*0.2,
                       endCenter: CGPoint(x: S, y: 0), endRadius: S*1.1, options: [])

// Tap-ripple rings behind the glyph.
let cx = S*0.5, cy = S*0.47
ctx.setLineWidth(24)
for (rad, a) in [(372.0, 0.16), (286.0, 0.24)] as [(CGFloat, Double)] {
    ctx.setStrokeColor(white(a))
    ctx.strokeEllipse(in: CGRect(x: cx-rad, y: cy-rad, width: rad*2, height: rad*2))
}

// hand.tap.fill glyph, solid white, centered (matches the menu-bar mark).
let cfg = NSImage.SymbolConfiguration(pointSize: 520, weight: .semibold)
if let base = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: nil),
   let conf = base.withSymbolConfiguration(cfg) {
    let sym = tinted(conf, .white)
    let sz = sym.size
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.22)
    shadow.shadowBlurRadius = 26
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    sym.draw(in: NSRect(x: (S - sz.width)/2, y: (S - sz.height)/2 - 6, width: sz.width, height: sz.height))
}

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!); exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
