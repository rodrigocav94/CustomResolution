import Foundation
import Testing
@testable import CustomResolution

struct ScaleResolutionEntryTests {
    private func entry(base64: String) throws -> ScaleResolutionEntry {
        let data = try #require(Data(base64Encoded: base64))
        return try #require(ScaleResolutionEntry(data: data))
    }

    /// Entries copied from the override files used while setting this up by hand.
    @Test func decodesKnownEntries() throws {
        #expect(try entry(base64: "AAAMJAAACHAAAAABACAAAA==") == ScaleResolutionEntry(width: 3108, height: 2160, isRetina: true))
        #expect(try entry(base64: "AAAGkAAAA7AAAAAB") == ScaleResolutionEntry(width: 1680, height: 944, isRetina: false))
        // Some tools write flags 0x9 / 0xa00000, which still include the Retina bit.
        #expect(try entry(base64: "AAANIAAAB2IAAAAJAKAAAA==") == ScaleResolutionEntry(width: 3360, height: 1890, isRetina: true))
    }

    @Test func encodesTheSameBytesAsTheManualSetup() {
        #expect(ScaleResolutionEntry(width: 3108, height: 2160, isRetina: true).data.base64EncodedString() == "AAAMJAAACHAAAAABACAAAA==")
        #expect(ScaleResolutionEntry(width: 1554, height: 1080, isRetina: false).data.count == 12)
    }

    @Test func rejectsShortData() {
        #expect(ScaleResolutionEntry(data: Data([0, 1, 2])) == nil)
    }
}
