import Foundation

enum AdminCommandError: LocalizedError {
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "The administrator password request was cancelled."
        case .failed(let message):
            message
        }
    }
}
