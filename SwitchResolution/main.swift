import AppKit

// Switch Resolution toggles a display between the custom resolution set up in Custom Resolution
// and the resolution that was active before. Run with --dry-run to print the plan without switching.

@MainActor
func showErrorAndExit(_ message: String) -> Never {
    if CommandLine.arguments.contains("--dry-run") {
        print(message)
        exit(1)
    }
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApp.activate()
    let alert = NSAlert()
    alert.messageText = "Couldn't switch resolution"
    alert.informativeText = message
    alert.runModal()
    exit(1)
}

var config = SharedConfig.load()
let mainDisplay = CGMainDisplayID()
// Prefer the main display, then any other display that has a custom resolution.
let displays = DisplayService.activeDisplays().sorted { $0.id == mainDisplay && $1.id != mainDisplay }

guard let display = displays.first(where: { config.profiles[$0.profileKey] != nil }),
      var profile = config.profiles[display.profileKey] else {
    showErrorAndExit("No custom resolution is set up for this display. Open Custom Resolution to add one.")
}

do {
    if CommandLine.arguments.contains("--dry-run") {
        let plan = try ResolutionToggle.plan(for: profile, on: display.id)
        let target = DisplayModeSpec(plan.target)
        let direction = plan.isSwitchingToCustom ? "to custom" : "back"
        print("\(display.name): would switch \(direction) to \(target.sizeDescription) (\(target.pixelSizeDescription) @\(Int(target.refreshRate))Hz)")
        exit(0)
    }
    try ResolutionToggle.toggle(&profile, on: display.id)
    config.profiles[display.profileKey] = profile
    try config.save()
} catch {
    showErrorAndExit(error.localizedDescription)
}
