import Foundation

/// Builds the contents of a display override file that adds a custom resolution.
enum OverrideFileBuilder {
    /// The entries that make macOS offer `width × height`.
    ///
    /// Recent Macs (seen on M4) ignore custom Retina entries, but they accept a standard entry at
    /// double size and derive a Retina mode from it. Older Macs honour the Retina entry directly,
    /// so all three are written.
    static func entries(width: Int, height: Int) -> [ScaleResolutionEntry] {
        [
            ScaleResolutionEntry(width: width * 2, height: height * 2, isRetina: false),
            ScaleResolutionEntry(width: width, height: height, isRetina: false),
            ScaleResolutionEntry(width: width * 2, height: height * 2, isRetina: true),
        ]
    }

    /// Returns a new override file that keeps everything in `original` (if any) and adds `width × height`.
    static func makeOverride(original: Data?, vendorID: UInt32, productID: UInt32, width: Int, height: Int) throws -> Data {
        var plist: [String: Any] = [:]
        if let original, !original.isEmpty {
            guard let parsed = try? PropertyListSerialization.propertyList(from: original, format: nil) as? [String: Any] else {
                throw OverrideError.unreadableOriginal
            }
            plist = parsed
        }
        plist["DisplayVendorID"] = Int(vendorID)
        plist["DisplayProductID"] = Int(productID)

        let added = entries(width: width, height: height)
        let kept = (plist["scale-resolutions"] as? [Data] ?? []).filter { data in
            guard let entry = ScaleResolutionEntry(data: data) else { return true }
            return !added.contains { $0.width == entry.width && $0.height == entry.height }
        }
        plist["scale-resolutions"] = added.map(\.data) + kept

        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }

    /// Whether an override file contains the entry that creates the Retina `width × height` mode.
    static func contains(_ override: Data?, width: Int, height: Int) -> Bool {
        guard let override,
              let plist = try? PropertyListSerialization.propertyList(from: override, format: nil) as? [String: Any],
              let items = plist["scale-resolutions"] as? [Data] else {
            return false
        }
        return items.contains { data in
            guard let entry = ScaleResolutionEntry(data: data) else { return false }
            return entry.width == width * 2 && entry.height == height * 2
        }
    }
}
