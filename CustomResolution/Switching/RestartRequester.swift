import Foundation

/// Shows macOS's standard "Are you sure you want to restart?" dialog.
@MainActor
enum RestartRequester {
    /// Returns false if macOS refused, so the caller can ask the user to restart manually.
    static func requestRestart() -> Bool {
        // 'aevt'/'rrst' asks loginwindow to show the Restart dialog (Apple Technical Q&A QA1134).
        guard let script = NSAppleScript(source: "tell application \"loginwindow\" to «event aevtrrst»") else {
            return false
        }
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        return errorInfo == nil
    }
}
