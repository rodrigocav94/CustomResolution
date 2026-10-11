import Foundation

enum DisplayServiceError: LocalizedError {
    case switchFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .switchFailed(let code):
            "macOS couldn't change the resolution (error \(code))."
        }
    }
}
