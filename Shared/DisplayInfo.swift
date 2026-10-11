import CoreGraphics

/// A connected display and the identifiers macOS uses to match its override file.
struct DisplayInfo: Identifiable, Hashable, Sendable {
    let id: CGDirectDisplayID
    let name: String
    let vendorID: UInt32
    let productID: UInt32

    /// Key for this display's profile in the shared config, e.g. "1e6d-77c3".
    var profileKey: String {
        "\(String(vendorID, radix: 16))-\(String(productID, radix: 16))"
    }
}
