import Foundation

/// One item in an override file's `scale-resolutions` array:
/// big-endian 32-bit width, height and flags, with a second flags word for Retina (HiDPI) entries.
struct ScaleResolutionEntry: Equatable, Sendable {
    private static let validFlag: UInt32 = 0x0000_0001
    private static let retinaFlag: UInt32 = 0x0020_0000

    var width: Int
    var height: Int
    var isRetina: Bool

    init(width: Int, height: Int, isRetina: Bool) {
        self.width = width
        self.height = height
        self.isRetina = isRetina
    }

    init?(data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 12, bytes.count.isMultiple(of: 4) else { return nil }
        let words = stride(from: 0, to: bytes.count, by: 4).map { offset in
            bytes[offset..<offset + 4].reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
        }
        width = Int(words[0])
        height = Int(words[1])
        isRetina = words.count >= 4 && words[3] & Self.retinaFlag != 0
    }

    var data: Data {
        var words = [UInt32(width), UInt32(height), Self.validFlag]
        if isRetina {
            words.append(Self.retinaFlag)
        }
        return Data(words.flatMap { word in
            [UInt8(word >> 24 & 0xFF), UInt8(word >> 16 & 0xFF), UInt8(word >> 8 & 0xFF), UInt8(word & 0xFF)]
        })
    }
}
