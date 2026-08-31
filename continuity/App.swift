import SwiftUI

@main
struct ContinuityApp: App {
    @State private var runner = Runner()

    init() {
        Feedback.requestNotifications()
        Updater.start()
    }

    var body: some Scene {
        MenuBarExtra(
            "Continuity",
            systemImage: runner.phones.isEmpty ? "iphone.slash" : "iphone.badge.play"
        ) {
            status
            Divider()
            ForEach(Action.all) { action in
                Button(action.title) { runner.run(action) }
            }
            Divider()
            history
            Button("Open log") { openLog() }
            if Updater.isConfigured {
                Button("Check for Updates…") { Updater.checkForUpdates() }
            }
            Button("Quit") { NSApp.terminate(nil) }
        }
    }

    @ViewBuilder private var status: some View {
        if runner.phones.isEmpty {
            Text("No iPhone detected")
        } else {
            ForEach(runner.phones) { phone in
                Text("\(phone.name) — \(phone.model)")
                Text(phone.summary)
            }
        }
        Button("Refresh") { runner.refresh() }
    }

    @ViewBuilder private var history: some View {
        if !runner.history.isEmpty {
            Section("Recent") {
                ForEach(runner.history.reversed()) { entry in
                    Text(entry.line)
                }
            }
        }
    }

    /// Console.app specifically: it tails the file and colours it, where the default
    /// handler for a .log is whatever text editor happens to claim the extension.
    private func openLog() {
        let console = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.open(
            [Feedback.logURL],
            withApplicationAt: console,
            configuration: NSWorkspace.OpenConfiguration())
    }
}
