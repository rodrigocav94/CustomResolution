import Foundation

enum OverrideError: LocalizedError {
    case unreadableOriginal
    case noBackup

    var errorDescription: String? {
        switch self {
        case .unreadableOriginal:
            "The display's existing override file couldn't be read, so it was left unchanged."
        case .noBackup:
            "There's no backup for this display. Nothing has been changed yet."
        }
    }
}
