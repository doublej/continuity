import Foundation
import UserNotifications

/// Every command result goes three places: the menu keeps recent entries, the log file
/// survives restarts, and a notification covers the case where the menu is already closed.
enum Feedback {
    static let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Logs/continuity.log")

    /// Asked for once at launch. Denied is fine — the log and the menu still report.
    static func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    static func notify(subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Continuity"
        content.subtitle = subtitle
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

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

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
