import SwiftUI

@main
struct ContinuityApp: App {
    @State private var runner = Runner()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Continuity", systemImage: "iphone.badge.play") {
            ForEach(Action.all) { action in
                Button(action.title) { runner.run(action) }
            }
            Divider()
            Text(runner.status)
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
    }
}

@MainActor @Observable
final class Runner {
    private(set) var status = "Ready"

    func run(_ action: Action) {
        status = "Running \(action.title)…"
        guard !action.admin else {
            return report(action, Shell.runAsAdmin(action.command))
        }
        Task { report(action, await Shell.run(action.command)) }
    }

    private func report(_ action: Action, _ output: String) {
        let text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        status = text.isEmpty ? "✓ \(action.title)" : text
    }
}
