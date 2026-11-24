import SwiftUI

@main
struct CounterApp: App {
    @State private var counter = Counter()

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Text(String(counter.value))
                    .accessibilityIdentifier("count")
                Button("Add one") { counter.increment() }
                    .accessibilityIdentifier("increment")
            }
            .padding()
        }
    }
}
