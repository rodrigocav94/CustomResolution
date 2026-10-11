import CoreGraphics

/// A serializable description of a display mode, used to remember and restore resolutions.
struct DisplayModeSpec: Codable, Equatable, Sendable {
    /// The "looks like" size, in points.
    var width: Int
    var height: Int
    /// The size macOS actually draws, in pixels. Twice the point size for Retina modes.
    var pixelWidth: Int
    var pixelHeight: Int
    var refreshRate: Double

    init(width: Int, height: Int, pixelWidth: Int, pixelHeight: Int, refreshRate: Double) {
        self.width = width
        self.height = height
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.refreshRate = refreshRate
    }

    init(_ mode: CGDisplayMode) {
        self.init(
            width: mode.width,
            height: mode.height,
            pixelWidth: mode.pixelWidth,
            pixelHeight: mode.pixelHeight,
            refreshRate: mode.refreshRate
        )
    }

    var sizeDescription: String { "\(width) × \(height)" }
    var pixelSizeDescription: String { "\(pixelWidth) × \(pixelHeight)" }
}
