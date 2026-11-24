import SwiftUI

@main
struct InterfaceApp: App {
    private let peer: ScriptedCamera
    @StateObject private var screen: CameraScreen
    @State private var continued = false

    init() {
        let peer = ScriptedCamera()
        self.peer = peer
        let screen = CameraScreen(camera: peer)
        _screen = StateObject(wrappedValue: screen)
        peer.onEvent?(.reportedMode(.color))
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Button("Switch mode") { screen.select(.mono) }
                Button("Next") { continued = true }.disabled(!screen.canContinue)
                if continued { Text("Advanced") }
                Divider()
                // Test controls deliver events to the same interface used by the model tests.
                Button("Deliver command reply") { peer.complete(.accepted) }
                    .disabled(peer.requests.isEmpty)
                Button("Deliver old state") { peer.onEvent?(.reportedMode(.color)) }
                Button("Deliver target state") { peer.onEvent?(.reportedMode(.mono)) }
            }
        }
    }
}
