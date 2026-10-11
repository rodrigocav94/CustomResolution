/// A common aspect ratio offered in the Presets menu.
struct AspectRatioPreset: Identifiable, Hashable, Sendable {
    let name: String
    let width: Int
    let height: Int

    var id: String { name }

    static let all = [
        AspectRatioPreset(name: "iPad / iPad Air 11″ (2360 × 1640)", width: 2360, height: 1640),
        AspectRatioPreset(name: "iPad Pro 11″ (2420 × 1668)", width: 2420, height: 1668),
        AspectRatioPreset(name: "iPad mini (2266 × 1488)", width: 2266, height: 1488),
        AspectRatioPreset(name: "4:3", width: 4, height: 3),
        AspectRatioPreset(name: "3:2", width: 3, height: 2),
        AspectRatioPreset(name: "16:10", width: 16, height: 10),
        AspectRatioPreset(name: "16:9", width: 16, height: 9),
        AspectRatioPreset(name: "21:9", width: 21, height: 9),
    ]
}
