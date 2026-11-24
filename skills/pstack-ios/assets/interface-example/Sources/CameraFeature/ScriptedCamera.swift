// This example fixture scripts public events only. It has no simulated firmware.
@MainActor
final class ScriptedCamera: CameraInterface {
    var onEvent: ((CameraEvent) -> Void)?
    private(set) var requests: [Mode] = []
    private var completions: [(CommandReply) -> Void] = []
    private var events: [(at: Int, send: () -> Void)] = []
    private(set) var now = 0

    func setMode(_ mode: Mode, completion: @escaping (CommandReply) -> Void) {
        requests.append(mode)
        completions.append(completion)
    }

    func complete(_ reply: CommandReply, request index: Int = 0) {
        completions[index](reply)
    }

    func schedule(at time: Int, _ send: @escaping () -> Void) {
        precondition(time >= now)
        events.append((time, send))
    }

    func advance(to time: Int) {
        precondition(time >= now)
        while let next = events.map(\.at).min(), next <= time {
            let index = events.firstIndex { $0.at == next }!
            let event = events.remove(at: index)
            now = event.at
            event.send()
        }
        now = time
    }
}
