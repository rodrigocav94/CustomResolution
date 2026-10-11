import Foundation

enum ResolutionToggleError: LocalizedError {
    case noCurrentMode
    case noModeToReturnTo
    case customModeUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .noCurrentMode:
            "Couldn't read the display's current resolution."
        case .noModeToReturnTo:
            "Couldn't find a resolution to switch back to."
        case .customModeUnavailable(let size):
            "\(size) isn't available on this display. If you just added it, restart your Mac. Otherwise open Custom Resolution to add it again."
        }
    }
}
