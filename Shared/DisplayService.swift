import AppKit

/// Reads and changes display modes through CoreGraphics.
enum DisplayService {
    /// `kDisplayModeDefaultFlag` from IOGraphicsTypes.h: the mode macOS picks by default.
    private static let defaultModeFlag: UInt32 = 0x0000_0004

    @MainActor
    static func activeDisplays() -> [DisplayInfo] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }

        return ids.prefix(Int(count)).map { id in
            let vendorID = CGDisplayVendorNumber(id)
            let productID = CGDisplayModelNumber(id)
            return DisplayInfo(
                id: id,
                name: screenName(for: id) ?? "Display \(String(vendorID, radix: 16))-\(String(productID, radix: 16))",
                vendorID: vendorID,
                productID: productID
            )
        }
    }

    static func currentMode(of display: CGDirectDisplayID) -> CGDisplayMode? {
        CGDisplayCopyDisplayMode(display)
    }

    /// Every mode, including the Retina twins macOS hides by default.
    static func allModes(of display: CGDirectDisplayID) -> [CGDisplayMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        return CGDisplayCopyAllDisplayModes(display, options) as? [CGDisplayMode] ?? []
    }

    /// The best desktop mode with this "looks like" size, preferring Retina, then the highest refresh rate.
    static func bestMode(of display: CGDirectDisplayID, width: Int, height: Int) -> CGDisplayMode? {
        allModes(of: display)
            .filter { $0.width == width && $0.height == height && $0.isUsableForDesktopGUI() }
            .max { ($0.pixelWidth, $0.refreshRate) < ($1.pixelWidth, $1.refreshRate) }
    }

    /// The mode closest to a saved one: same size, same pixels if possible, nearest refresh rate.
    static func mode(of display: CGDirectDisplayID, matching spec: DisplayModeSpec) -> CGDisplayMode? {
        let sameSize = allModes(of: display)
            .filter { $0.width == spec.width && $0.height == spec.height && $0.isUsableForDesktopGUI() }
        let samePixels = sameSize.filter { $0.pixelWidth == spec.pixelWidth && $0.pixelHeight == spec.pixelHeight }
        return (samePixels.isEmpty ? sameSize : samePixels)
            .min { abs($0.refreshRate - spec.refreshRate) < abs($1.refreshRate - spec.refreshRate) }
    }

    /// The mode macOS uses by default for this display.
    static func defaultMode(of display: CGDirectDisplayID) -> CGDisplayMode? {
        allModes(of: display)
            .filter { $0.ioFlags & defaultModeFlag != 0 && $0.isUsableForDesktopGUI() }
            .max { ($0.pixelWidth, $0.refreshRate) < ($1.pixelWidth, $1.refreshRate) }
    }

    /// Switches the display to `mode` and keeps it after restarts.
    static func apply(_ mode: CGDisplayMode, to display: CGDirectDisplayID) throws {
        var config: CGDisplayConfigRef?
        let began = CGBeginDisplayConfiguration(&config)
        guard began == .success else { throw DisplayServiceError.switchFailed(began.rawValue) }
        CGConfigureDisplayWithDisplayMode(config, display, mode, nil)
        let completed = CGCompleteDisplayConfiguration(config, .permanently)
        guard completed == .success else { throw DisplayServiceError.switchFailed(completed.rawValue) }
    }

    @MainActor
    private static func screenName(for display: CGDirectDisplayID) -> String? {
        NSScreen.screens.first { screen in
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            return number?.uint32Value == display
        }?.localizedName
    }
}
