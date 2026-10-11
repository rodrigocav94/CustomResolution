import Testing
@testable import CustomResolution

struct CustomResolutionSpecTests {
    @Test func iPadRatioAt1080MatchesTheManualSetup() {
        let spec = CustomResolutionSpec(ratioWidth: 2360, ratioHeight: 1640, height: 1080)
        #expect(spec.width == 1554)
        #expect(spec.retinaWidth == 3108)
        #expect(spec.retinaHeight == 2160)
        #expect(spec.isValid)
    }

    @Test func sixteenByNineAt1080IsFullHD() {
        let spec = CustomResolutionSpec(ratioWidth: 16, ratioHeight: 9, height: 1080)
        #expect(spec.width == 1920)
    }

    @Test func widthIsRoundedToAnEvenNumber() {
        let spec = CustomResolutionSpec(ratioWidth: 4, ratioHeight: 3, height: 1001)
        #expect(spec.width.isMultiple(of: 2))
    }

    @Test(arguments: [(0, 3, 1080), (4, 0, 1080), (4, 3, 100), (4, 3, 9000)])
    func invalidInputIsRejected(ratioWidth: Int, ratioHeight: Int, height: Int) {
        let spec = CustomResolutionSpec(ratioWidth: ratioWidth, ratioHeight: ratioHeight, height: height)
        #expect(!spec.isValid)
    }
}
