import CoreGraphics

/// What a toggle will do: the mode to switch to and, when entering the custom size, the mode to remember.
struct ResolutionTogglePlan {
    let target: CGDisplayMode
    let modeToRemember: DisplayModeSpec?

    var isSwitchingToCustom: Bool { modeToRemember != nil }
}
