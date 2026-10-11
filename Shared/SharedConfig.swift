import Foundation

/// Settings shared by Custom Resolution and the Switch Resolution shortcut,
/// stored as JSON in ~/Library/Application Support/CustomResolution.
struct SharedConfig: Codable, Sendable {
    /// Profiles keyed by `DisplayInfo.profileKey`.
    var profiles: [String: ResolutionProfile] = [:]

    static let directory = URL.applicationSupportDirectory.appending(path: "CustomResolution", directoryHint: .isDirectory)
    static let fileURL = directory.appending(path: "config.json")

    /// Loads the saved config, or an empty one if there is none yet.
    static func load() -> SharedConfig {
        guard let data = try? Data(contentsOf: fileURL),
              let config = try? JSONDecoder().decode(SharedConfig.self, from: data) else {
            return SharedConfig()
        }
        return config
    }

    func save() throws {
        try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: Self.fileURL, options: .atomic)
    }
}
