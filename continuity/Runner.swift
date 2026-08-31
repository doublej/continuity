import AVFoundation
import Observation

/// Runs a command, then reports the result three ways: menu history, log file, notification.
@MainActor @Observable
final class Runner {
    struct Entry: Identifiable {
        let id = UUID()
        let time: Date
        let title: String
        let detail: String

        var line: String {
            let first = detail.split(separator: "\n").first.map(String.init) ?? detail
            return "\(time.formatted(date: .omitted, time: .shortened))  \(title) — \(first)"
        }
    }

    private(set) var phones: [Phone] = []
    private(set) var history: [Entry] = []

    init() {
        refresh()
        observeDeviceChanges()
    }

    func refresh() {
        phones = Status.phones()
    }

    func run(_ action: Action) {
        guard !action.admin else {
            return report(action, Shell.runAsAdmin(action.command))
        }
        Task { report(action, await Shell.run(action.command)) }
    }

    private func report(_ action: Action, _ output: String) {
        let text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = Entry(time: Date(), title: action.title, detail: text.isEmpty ? "done" : text)
        history = Array((history + [entry]).suffix(8))
        Feedback.log(entry.detail.split(separator: "\n").joined(separator: " · "), for: action.title)
        Task {
            await Feedback.notify(subtitle: action.title, body: entry.detail)
            // Killed agents are relaunched on demand — give launchd a moment before re-reading.
            try? await Task.sleep(for: .seconds(2))
            refresh()
        }
    }

    private func observeDeviceChanges() {
        for name in [AVCaptureDevice.wasConnectedNotification,
                        AVCaptureDevice.wasDisconnectedNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
        }
    }
}
