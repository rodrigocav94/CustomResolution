import Foundation

/// Runs a shell command as root after macOS asks for an administrator password.
@MainActor
enum AdminCommandRunner {
    /// AppleScript's "User canceled" error number.
    private static let userCancelledError = -128

    static func run(_ command: String, prompt: String) throws {
        let source = "do shell script \(appleScriptString(command)) with prompt \(appleScriptString(prompt)) with administrator privileges"
        guard let script = NSAppleScript(source: source) else {
            throw AdminCommandError.failed("The command couldn't be prepared.")
        }

        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        guard let errorInfo else { return }

        if errorInfo[NSAppleScript.errorNumber] as? Int == userCancelledError {
            throw AdminCommandError.cancelled
        }
        throw AdminCommandError.failed(errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error.")
    }

    /// Wraps a value in single quotes so the shell treats it as one argument.
    static func shellQuoted(_ value: String) -> String {
        "'" + value.replacing("'", with: "'\\''") + "'"
    }

    /// Wraps a value in an AppleScript string literal.
    private static func appleScriptString(_ value: String) -> String {
        "\"" + value.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"") + "\""
    }
}
