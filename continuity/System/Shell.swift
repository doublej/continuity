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

    /// Root, via the standard macOS authorisation prompt.
    ///
    /// Routed through an `osascript` subprocess rather than `NSAppleScript` in-process:
    /// under the Hardened Runtime, pulling Standard Additions into a signed app is a
    /// library-validation problem, and a separate process sidesteps it entirely.
    /// Cancelling the prompt comes back as "User canceled. (-128)", which is a result
    /// worth showing, so it is left to travel the normal path.
    static func runAsAdmin(_ command: String) async -> String {
        let source = "do shell script \(appleScriptLiteral(command)) with administrator privileges"
        return await run("osascript -e \(quote(source))")
    }

    /// Single-quote a string so `zsh -c` treats it as one literal argument.
    static func quote(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// An AppleScript string literal. The payload is a shell command or command output,
    /// so it can contain anything.
    static func appleScriptLiteral(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
