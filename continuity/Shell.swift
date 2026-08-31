import Foundation

enum Shell {
    /// Runs off the main thread; stderr is folded into stdout so `killall`'s
    /// "No matching processes" lands in the menu instead of vanishing.
    static func run(_ command: String) async -> String {
        await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            do { try process.run() } catch { return "failed: \(error.localizedDescription)" }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(bytes: data, encoding: .utf8) ?? ""
        }.value
    }

    /// Root via the standard macOS auth prompt. Blocks on the main thread — the prompt is
    /// modal anyway, and the app has no other UI to keep responsive.
    @MainActor
    static func runAsAdmin(_ command: String) -> String {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escaped)\" with administrator privileges"
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            return error[NSAppleScript.errorMessage] as? String ?? "authorisation failed"
        }
        return result?.stringValue ?? ""
    }
}

extension Shell {
    /// Single-quote a string so `zsh -c` treats it as one literal argument.
    static func quote(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
