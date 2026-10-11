import Foundation

enum ShortcutInstallerError: LocalizedError {
    case missingFromBundle

    var errorDescription: String? {
        switch self {
        case .missingFromBundle:
            "Switch Resolution is missing from this copy of Custom Resolution. Try downloading the app again."
        }
    }
}
