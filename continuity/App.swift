import SwiftUI

@main
struct ContinuityApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("continuity")
                .font(.largeTitle)
            Text("Menu bar commands to kick Continuity Camera and Mic back to life")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
