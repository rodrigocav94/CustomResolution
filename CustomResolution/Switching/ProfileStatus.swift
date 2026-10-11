/// Where a display's custom resolution stands.
enum ProfileStatus: Equatable {
    /// No custom resolution has been added.
    case notSetUp
    /// The override file has the custom resolution, but macOS needs a restart to offer it.
    case needsRestart
    /// The custom resolution can be selected.
    case available
    /// The original file is back, but the custom resolution stays until the next restart.
    case removalPending
}
