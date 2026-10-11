import AppKit
import Observation

/// The window's state, and every action it offers.
@MainActor
@Observable
final class AppModel {
    private(set) var displays: [DisplayInfo] = []
    var selectedDisplayID: CGDirectDisplayID?
    var spec = CustomResolutionSpec(ratioWidth: 2360, ratioHeight: 1640, height: 1080)

    private(set) var currentMode: DisplayModeSpec?
    private(set) var status = ProfileStatus.notSetUp
    private(set) var isShowingCustom = false
    private(set) var hasBackup = false
    private(set) var isShortcutInstalled = false
    private var config = SharedConfig()

    var presentedAlert: AppAlert?
    var isAlertPresented = false

    init() {
        loadSelectedProfile()
    }

    var selectedDisplay: DisplayInfo? {
        displays.first { $0.id == selectedDisplayID }
    }

    var profile: ResolutionProfile? {
        selectedDisplay.flatMap { config.profiles[$0.profileKey] }
    }

    var canAddResolution: Bool {
        selectedDisplay != nil && spec.isValid
    }

    var specWarning: String? {
        guard spec.isValid, spec.retinaWidth > CustomResolutionSpec.retinaWidthLimit else { return nil }
        return "Wider than \(CustomResolutionSpec.retinaWidthLimit / 2) points, so M4 and M5 Macs may refuse it."
    }

    var toggleTitle: String {
        guard let profile else { return "Switch" }
        return if isShowingCustom {
            "Switch Back to \(profile.previousMode?.sizeDescription ?? "Default")"
        } else {
            "Switch to \(profile.sizeDescription)"
        }
    }

    /// Re-reads displays, the shared config and the override file.
    func refresh() {
        config = SharedConfig.load()
        displays = DisplayService.activeDisplays()
        if selectedDisplay == nil {
            let mainDisplay = CGMainDisplayID()
            selectedDisplayID = displays.first { $0.id == mainDisplay }?.id ?? displays.first?.id
        }
        isShortcutInstalled = ShortcutInstaller.isInstalled

        guard let display = selectedDisplay else {
            currentMode = nil
            status = .notSetUp
            isShowingCustom = false
            hasBackup = false
            return
        }
        currentMode = DisplayService.currentMode(of: display.id).map { DisplayModeSpec($0) }
        hasBackup = OverrideManager.hasBackup(for: display)
        status = Self.status(of: profile, on: display)
        isShowingCustom = profile.map { ResolutionToggle.isShowingCustom($0, on: display.id) } ?? false
    }

    /// Fills the form from the selected display's saved profile, or starts from its current height.
    func loadSelectedProfile() {
        refresh()
        if let profile {
            spec = CustomResolutionSpec(ratioWidth: profile.ratioWidth, ratioHeight: profile.ratioHeight, height: profile.height)
        } else if let currentMode {
            spec.height = currentMode.height
        }
    }

    func apply(_ preset: AspectRatioPreset) {
        spec.ratioWidth = preset.width
        spec.ratioHeight = preset.height
    }

    func addResolution() {
        guard let display = selectedDisplay, spec.isValid else { return }
        let spec = spec
        perform {
            try OverrideManager.install(width: spec.width, height: spec.height, for: display)

            var profile = config.profiles[display.profileKey]
                ?? ResolutionProfile(displayName: display.name, ratioWidth: 0, ratioHeight: 0, width: 0, height: 0)
            profile.displayName = display.name
            profile.ratioWidth = spec.ratioWidth
            profile.ratioHeight = spec.ratioHeight
            profile.width = spec.width
            profile.height = spec.height
            config.profiles[display.profileKey] = profile
            try config.save()

            refresh()
            present(AppAlert(
                title: "Restart to Finish",
                message: "\(spec.sizeDescription) was added for \(display.name). macOS picks up new resolutions after a restart.",
                offersRestart: true
            ))
        }
    }

    func toggleResolution() {
        guard let display = selectedDisplay, var profile else { return }
        perform {
            try ResolutionToggle.toggle(&profile, on: display.id)
            config.profiles[display.profileKey] = profile
            try config.save()
            refresh()
        }
    }

    func restoreBackup() {
        guard let display = selectedDisplay else { return }
        perform {
            try OverrideManager.restoreBackup(for: display)

            // Leave the custom size now, so the display doesn't come back from the restart in a mode that's gone.
            if var profile, ResolutionToggle.isShowingCustom(profile, on: display.id) {
                try ResolutionToggle.toggle(&profile, on: display.id)
                config.profiles[display.profileKey] = profile
                try config.save()
            }

            refresh()
            present(AppAlert(
                title: "Original Settings Restored",
                message: "The custom resolution disappears after you restart.",
                offersRestart: true
            ))
        }
    }

    func installShortcut() {
        perform {
            try ShortcutInstaller.install()
            isShortcutInstalled = true
        }
    }

    func restart() {
        if !RestartRequester.requestRestart() {
            present(AppAlert(title: "Restart Your Mac", message: "Choose Restart from the Apple menu to finish."))
        }
    }

    /// Keeps the window current when displays change or the Switch Resolution shortcut is used.
    func observeSystemChanges() async {
        let names = [NSApplication.didChangeScreenParametersNotification, NSApplication.didBecomeActiveNotification]
        await withDiscardingTaskGroup { group in
            for name in names {
                group.addTask {
                    for await _ in NotificationCenter.default.notifications(named: name) {
                        await self.refresh()
                    }
                }
            }
        }
    }

    private static func status(of profile: ResolutionProfile?, on display: DisplayInfo) -> ProfileStatus {
        guard let profile else { return .notSetUp }
        let isInOverride = OverrideFileBuilder.contains(
            OverrideManager.currentOverride(for: display),
            width: profile.width,
            height: profile.height
        )
        let isOffered = DisplayService.bestMode(of: display.id, width: profile.width, height: profile.height) != nil

        return switch (isInOverride, isOffered) {
        case (true, true): .available
        case (true, false): .needsRestart
        case (false, true): .removalPending
        case (false, false): .notSetUp
        }
    }

    /// Runs an action and shows any error, except a cancelled password prompt.
    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch AdminCommandError.cancelled {
            return
        } catch {
            present(AppAlert(title: "Something Went Wrong", message: error.localizedDescription))
        }
    }

    private func present(_ alert: AppAlert) {
        presentedAlert = alert
        isAlertPresented = true
    }
}
