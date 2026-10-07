// Dibuixa la icona de l'app: gradient pastel + unicorni.
// Usa (des de l'arrel del projecte): xcrun swift tools/dibuixa_icona.swift
// Sortida: Packaging/icon_1024.png
import AppKit
import CoreGraphics

let Mida: CGFloat = 1024
let img = NSImage(size: NSSize(width: Mida, height: Mida))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Fons: gradient diagonal rosa -> lila -> blau cel (tema pastel)
let colors = [NSColor(calibratedRed: 1.00, green: 0.75, blue: 0.88, alpha: 1).cgColor,
              NSColor(calibratedRed: 0.80, green: 0.68, blue: 1.00, alpha: 1).cgColor,
              NSColor(calibratedRed: 0.68, green: 0.85, blue: 1.00, alpha: 1).cgColor] as CFArray
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: colors, locations: [0, 0.5, 1])!
ctx.drawLinearGradient(grad, start: .zero,
                       end: CGPoint(x: Mida, y: Mida), options: [])

// Bombollas de llum toves (bokeh) al fons
for (x, y, r, a) in [(180.0, 820.0, 130.0, 0.25), (850.0, 880.0, 90.0, 0.2),
                     (140.0, 180.0, 100.0, 0.2), (890.0, 160.0, 120.0, 0.22),
                     (520.0, 940.0, 70.0, 0.18)] {
    ctx.setFillColor(NSColor.white.withAlphaComponent(a).cgColor)
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
}

// Emoji/text centrat
func dibuixa(_ text: String, mida: CGFloat, cx: CGFloat, cy: CGFloat) {
    let attr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: mida)]
    let s = NSAttributedString(string: text, attributes: attr)
    let sSize = s.size()
    s.draw(at: NSPoint(x: cx - sSize.width / 2, y: cy - sSize.height / 2))
}

dibuixa("🦄", mida: 560, cx: Mida / 2, cy: Mida / 2 - 10)
dibuixa("✨", mida: 150, cx: 790, cy: 800)
dibuixa("✨", mida: 110, cx: 240, cy: 250)

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let bmp = NSBitmapImageRep(data: tiff),
      let png = bmp.representation(using: .png, properties: [:]) else {
    fatalError("Error generant PNG")
}
let dir = FileManager.default
try? dir.createDirectory(atPath: "Packaging", withIntermediateDirectories: true)
try! png.write(to: URL(fileURLWithPath: "Packaging/icon_1024.png"))
print("OK: Packaging/icon_1024.png")
