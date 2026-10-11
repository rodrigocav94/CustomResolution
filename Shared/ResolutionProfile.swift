/// The custom resolution set up for one display, plus the mode to switch back to.
struct ResolutionProfile: Codable, Equatable, Sendable {
    var displayName: String
    var ratioWidth: Int
    var ratioHeight: Int
    /// The custom "looks like" size, in points.
    var width: Int
    var height: Int
    /// The mode that was active before switching to the custom size.
    var previousMode: DisplayModeSpec?

    var sizeDescription: String { "\(width) × \(height)" }
}
