import Foundation

/// Locates, backs up, writes and restores display override files in /Library/Displays.
@MainActor
enum OverrideManager {
    static let overridesDirectory = URL(filePath: "/Library/Displays/Contents/Resources/Overrides", directoryHint: .isDirectory)
    static let backupsDirectory = SharedConfig.directory.appending(path: "Backups", directoryHint: .isDirectory)

    static func overrideURL(for display: DisplayInfo) -> URL {
        overridesDirectory.appending(path: relativePath(for: display))
    }

    static func currentOverride(for display: DisplayInfo) -> Data? {
        try? Data(contentsOf: overrideURL(for: display))
    }

    static func hasBackup(for display: DisplayInfo) -> Bool {
        exists(backupURL(for: display)) || exists(noOriginalMarkerURL(for: display))
    }

    /// Writes an override that adds `width × height`, after macOS asks for an administrator password.
    /// The display's original file is backed up first, and the new file is always built from that original.
    static func install(width: Int, height: Int, for display: DisplayInfo) throws {
        try backUpIfNeeded(display)
        let original = try? Data(contentsOf: backupURL(for: display))
        let override = try OverrideFileBuilder.makeOverride(
            original: original,
            vendorID: display.vendorID,
            productID: display.productID,
            width: width,
            height: height
        )

        let temporary = URL.temporaryDirectory.appending(path: "DisplayOverride-\(UUID().uuidString)")
        try override.write(to: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }

        try AdminCommandRunner.run(
            installCommand(from: temporary, to: overrideURL(for: display)),
            prompt: "Custom Resolution wants to add a \(width) × \(height) resolution for \(display.name)."
        )
    }

    /// Puts back the display's original override file, or removes ours if it had none.
    static func restoreBackup(for display: DisplayInfo) throws {
        let target = overrideURL(for: display)
        let prompt = "Custom Resolution wants to restore the original settings file for \(display.name)."

        if exists(backupURL(for: display)) {
            try AdminCommandRunner.run(installCommand(from: backupURL(for: display), to: target), prompt: prompt)
        } else if exists(noOriginalMarkerURL(for: display)) {
            try AdminCommandRunner.run("/bin/rm -f \(AdminCommandRunner.shellQuoted(target.path(percentEncoded: false)))", prompt: prompt)
        } else {
            throw OverrideError.noBackup
        }
    }

    /// Saves the display's override file, or a marker saying it had none, the first time it's changed.
    private static func backUpIfNeeded(_ display: DisplayInfo) throws {
        guard !hasBackup(for: display) else { return }
        let backup = backupURL(for: display)
        try FileManager.default.createDirectory(at: backup.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let current = currentOverride(for: display) {
            try current.write(to: backup)
        } else {
            try Data().write(to: noOriginalMarkerURL(for: display))
        }
    }

    private static func backupURL(for display: DisplayInfo) -> URL {
        backupsDirectory.appending(path: relativePath(for: display))
    }

    private static func noOriginalMarkerURL(for display: DisplayInfo) -> URL {
        backupURL(for: display).appendingPathExtension("none")
    }

    /// The vendor and product folder layout macOS expects, e.g. "DisplayVendorID-1e6d/DisplayProductID-77c3".
    private static func relativePath(for display: DisplayInfo) -> String {
        "DisplayVendorID-\(String(display.vendorID, radix: 16))/DisplayProductID-\(String(display.productID, radix: 16))"
    }

    private static func installCommand(from source: URL, to target: URL) -> String {
        let source = AdminCommandRunner.shellQuoted(source.path(percentEncoded: false))
        let target = target.path(percentEncoded: false)
        let folder = AdminCommandRunner.shellQuoted((target as NSString).deletingLastPathComponent)
        let quotedTarget = AdminCommandRunner.shellQuoted(target)
        return "/bin/mkdir -p \(folder) && /bin/cp \(source) \(quotedTarget) && /usr/sbin/chown root:wheel \(quotedTarget) && /bin/chmod 644 \(quotedTarget)"
    }

    private static func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }
}
