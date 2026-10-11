// Generates the AppIcon asset catalogs for both apps. Run from the project root:
//   swift Scripts/make-icons.swift
import AppKit

struct IconSpec {
    let folder: String
    let symbol: String
    let top: NSColor
    let bottom: NSColor
}

let specs = [
    IconSpec(folder: "CustomResolution/Assets.xcassets", symbol: "plus.rectangle.on.rectangle",
             top: NSColor(calibratedRed: 0.13, green: 0.72, blue: 0.67, alpha: 1),
             bottom: NSColor(calibratedRed: 0.11, green: 0.42, blue: 0.80, alpha: 1)),
    IconSpec(folder: "SwitchResolution/Assets.xcassets", symbol: "aspectratio",
             top: NSColor(calibratedRed: 0.24, green: 0.52, blue: 0.98, alpha: 1),
             bottom: NSColor(calibratedRed: 0.36, green: 0.28, blue: 0.90, alpha: 1)),
]

func render(_ spec: IconSpec, pixels: Int) -> Data {
    let size = CGFloat(pixels)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                                     samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else { fatalError("Couldn't create bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // macOS icon grid: an 824/1024 rounded tile centred in the canvas.
    let inset = size * 100 / 1024
    let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let path = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGradient(starting: spec.top, ending: spec.bottom)?.draw(in: path, angle: -90)
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: spec.symbol, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let s = symbol.size
        symbol.draw(in: NSRect(x: (size - s.width) / 2, y: (size - s.height) / 2, width: s.width, height: s.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("Couldn't encode PNG") }
    return png
}

for spec in specs {
    let iconSet = URL(filePath: spec.folder).appending(path: "AppIcon.appiconset")
    try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)
    try Data(#"{"info":{"author":"xcode","version":1}}"#.utf8).write(to: URL(filePath: spec.folder).appending(path: "Contents.json"))

    var images: [[String: String]] = []
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
            try render(spec, pixels: points * scale).write(to: iconSet.appending(path: name))
            images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
        }
    }
    let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        .write(to: iconSet.appending(path: "Contents.json"))
    print("Wrote \(iconSet.path)")
}
