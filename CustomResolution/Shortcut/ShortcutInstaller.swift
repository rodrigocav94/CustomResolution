import AppKit

/// Copies the Switch Resolution app bundled inside Custom Resolution into ~/Applications.
@MainActor
enum ShortcutInstaller {
    private static let appName = "Switch Resolution"

    static var destination: URL {
        URL.homeDirectory
            .appending(path: "Applications", directoryHint: .isDirectory)
            .appending(path: "\(appName).app", directoryHint: .isDirectory)
    }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: destination.path(percentEncoded: false))
    }

    /// Installs or replaces the shortcut, then shows it in Finder.
    static func install() throws {
        guard let source = Bundle.main.url(forResource: appName, withExtension: "app") else {
            throw ShortcutInstallerError.missingFromBundle
        }
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if isInstalled {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
        try clearQuarantine(at: destination)
        NSWorkspace.shared.activateFileViewerSelecting([destination])
    }

    /// The copy inherits the download quarantine flag if Custom Resolution was downloaded.
    /// The user already approved this app, so the flag is cleared to avoid a second Gatekeeper prompt.
    private static func clearQuarantine(at url: URL) throws {
        let process = try Process.run(
            URL(filePath: "/usr/bin/xattr"),
            arguments: ["-dr", "com.apple.quarantine", url.path(percentEncoded: false)]
        )
        process.waitUntilExit()
    }
}
