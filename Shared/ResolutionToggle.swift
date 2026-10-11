import CoreGraphics

/// Switches a display between its custom resolution and the one that was active before.
enum ResolutionToggle {
    static func isShowingCustom(_ profile: ResolutionProfile, on display: CGDirectDisplayID) -> Bool {
        guard let current = DisplayService.currentMode(of: display) else { return false }
        return current.width == profile.width && current.height == profile.height
    }

    static func plan(for profile: ResolutionProfile, on display: CGDirectDisplayID) throws -> ResolutionTogglePlan {
        guard let current = DisplayService.currentMode(of: display) else {
            throw ResolutionToggleError.noCurrentMode
        }

        if current.width == profile.width && current.height == profile.height {
            // Go back to the remembered mode, or to the display's default if it no longer exists.
            let previous = profile.previousMode.flatMap { DisplayService.mode(of: display, matching: $0) }
            guard let target = previous ?? DisplayService.defaultMode(of: display) else {
                throw ResolutionToggleError.noModeToReturnTo
            }
            return ResolutionTogglePlan(target: target, modeToRemember: nil)
        }

        guard let custom = DisplayService.bestMode(of: display, width: profile.width, height: profile.height) else {
            throw ResolutionToggleError.customModeUnavailable(profile.sizeDescription)
        }
        return ResolutionTogglePlan(target: custom, modeToRemember: DisplayModeSpec(current))
    }

    /// Performs the toggle and records the mode to return to in `profile`. Returns the new mode.
    @discardableResult
    static func toggle(_ profile: inout ResolutionProfile, on display: CGDirectDisplayID) throws -> DisplayModeSpec {
        let plan = try plan(for: profile, on: display)
        try DisplayService.apply(plan.target, to: display)
        if let remembered = plan.modeToRemember {
            profile.previousMode = remembered
        }
        return DisplayModeSpec(plan.target)
    }
}
