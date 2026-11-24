import Combine

enum Mode: Equatable { case color, mono }
enum CommandReply: Equatable { case accepted, timedOut }
enum CameraEvent {
    case frame(Int)
    case reportedMode(Mode)
}

@MainActor
protocol CameraInterface: AnyObject {
    func setMode(_ mode: Mode, completion: @escaping (CommandReply) -> Void)
    var onEvent: ((CameraEvent) -> Void)? { get set }
}

@MainActor
final class CameraScreen: ObservableObject {
    @Published private(set) var canContinue = false
    @Published private(set) var reportedMode: Mode?
    @Published private(set) var lastFrame: Int?
    @Published private(set) var reply: CommandReply?
    private let camera: any CameraInterface
    private var requested: Mode?
    private var requestNumber = 0

    init(camera: any CameraInterface) {
        self.camera = camera
        camera.onEvent = { [weak self] event in self?.receive(event) }
    }

    func select(_ mode: Mode) {
        requested = mode
        canContinue = false
        reply = nil
        requestNumber += 1
        let number = requestNumber
        camera.setMode(mode) { [weak self] reply in
            guard let self, self.requestNumber == number else { return }
            self.reply = reply
        }
    }

    private func receive(_ event: CameraEvent) {
        switch event {
        case .frame(let number):
            lastFrame = number
        case .reportedMode(let mode):
            reportedMode = mode
            canContinue = requested == mode
        }
    }
}
