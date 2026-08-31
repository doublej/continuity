import Foundation

/// Every command result goes three places: the menu keeps recent entries, the log file
/// survives restarts, and a notification covers the case where the menu is already closed.
enum Feedback {
    static let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Logs/continuity.log")

    static func log(_ detail: String, for title: String, to url: URL = logURL) {
        let stamped = "\(stamp.string(from: Date()))  \(title) — \(detail)\n"
        guard let data = stamped.data(using: .utf8) else { return }
        guard let handle = try? FileHandle(forWritingTo: url) else {
            try? data.write(to: url)
            return
        }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)  // best effort: the log must never break a command
    }

    /// Posted via `osascript` because an unbundled SwiftPM binary has no bundle identifier,
    /// which is what `UNUserNotificationCenter` needs.
    static func notify(subtitle: String, body: String) async {
        let source = "display notification \(literal(body)) "
            + "with title \"Continuity\" subtitle \(literal(subtitle))"
        _ = await Shell.run("osascript -e \(Shell.quote(source))")
    }

    /// An AppleScript string literal — the body is command output, so it can contain anything.
    static func literal(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
