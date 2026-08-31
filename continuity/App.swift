import SwiftUI

@main
struct ContinuityApp: App {
    @State private var runner = Runner()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Continuity", systemImage: runner.phones.isEmpty ? "iphone.slash" : "iphone.badge.play") {
            status
            Divider()
            ForEach(Action.all) { action in
                Button(action.title) { runner.run(action) }
            }
            Divider()
            history
            Button("Open log") { NSWorkspace.shared.open(Feedback.logURL) }
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
}
