/// Turns an aspect ratio and a "looks like" height into the custom resolution to add.
struct CustomResolutionSpec: Equatable, Sendable {
    /// Retina framebuffer width that M4 and M5 Macs refuse to go beyond on external displays.
    static let retinaWidthLimit = 6720
    static let heightRange = 400...4320

    var ratioWidth: Int
    var ratioHeight: Int
    /// The "looks like" height, in points.
    var height: Int

    /// The "looks like" width, rounded to an even number of points.
    var width: Int {
        guard ratioWidth > 0, ratioHeight > 0 else { return 0 }
        let exact = Double(height) * Double(ratioWidth) / Double(ratioHeight)
        return Int((exact / 2).rounded()) * 2
    }

    /// The pixel size macOS draws at for the sharp Retina version.
    var retinaWidth: Int { width * 2 }
    var retinaHeight: Int { height * 2 }

    var isValid: Bool {
        ratioWidth > 0 && ratioHeight > 0 && Self.heightRange.contains(height) && Self.heightRange.contains(width)
    }

    var sizeDescription: String { "\(width) × \(height)" }
    var retinaSizeDescription: String { "\(retinaWidth) × \(retinaHeight)" }
}
