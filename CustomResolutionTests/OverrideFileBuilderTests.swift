import Foundation
import Testing
@testable import CustomResolution

struct OverrideFileBuilderTests {
    private func entries(in override: Data) throws -> [ScaleResolutionEntry] {
        let plist = try #require(try PropertyListSerialization.propertyList(from: override, format: nil) as? [String: Any])
        let items = try #require(plist["scale-resolutions"] as? [Data])
        return items.compactMap(ScaleResolutionEntry.init(data:))
    }

    @Test func newOverrideHasIdentifiersAndAllThreeEntries() throws {
        let override = try OverrideFileBuilder.makeOverride(original: nil, vendorID: 0x1e6d, productID: 0x77c3, width: 1554, height: 1080)
        let plist = try #require(try PropertyListSerialization.propertyList(from: override, format: nil) as? [String: Any])

        #expect(plist["DisplayVendorID"] as? Int == 0x1e6d)
        #expect(plist["DisplayProductID"] as? Int == 0x77c3)
        #expect(try entries(in: override) == OverrideFileBuilder.entries(width: 1554, height: 1080))
        #expect(OverrideFileBuilder.contains(override, width: 1554, height: 1080))
        #expect(!OverrideFileBuilder.contains(override, width: 1920, height: 1080))
    }

    @Test func keepsOriginalEntriesAndReplacesMatchingOnes() throws {
        let originalPlist: [String: Any] = [
            "DisplayVendorID": 0x1e6d,
            "DisplayProductID": 0x77c3,
            "target-default-ppmm": 10.07,
            "scale-resolutions": [
                ScaleResolutionEntry(width: 1680, height: 944, isRetina: false).data,
                ScaleResolutionEntry(width: 3108, height: 2160, isRetina: true).data,
            ],
        ]
        let original = try PropertyListSerialization.data(fromPropertyList: originalPlist, format: .xml, options: 0)

        let override = try OverrideFileBuilder.makeOverride(original: original, vendorID: 0x1e6d, productID: 0x77c3, width: 1554, height: 1080)
        let plist = try #require(try PropertyListSerialization.propertyList(from: override, format: nil) as? [String: Any])
        let result = try entries(in: override)

        #expect(plist["target-default-ppmm"] as? Double == 10.07)
        #expect(result.contains(ScaleResolutionEntry(width: 1680, height: 944, isRetina: false)))
        #expect(result.count == 4, "The duplicate 3108 × 2160 entry should be replaced, not repeated")
    }

    @Test func unreadableOriginalIsRefused() {
        #expect(throws: OverrideError.self) {
            try OverrideFileBuilder.makeOverride(original: Data("not a plist".utf8), vendorID: 1, productID: 2, width: 1554, height: 1080)
        }
    }
}
