import Combine
import XCTest
@testable import CameraFeature

final class CameraScreenTests: XCTestCase {
    @MainActor func testNextRemainsDisabledUntilTargetIsReported() async {
        let port = ScriptedCamera()
        let screen = CameraScreen(camera: port)
        var changes: [Int] = []
        let observation = screen.$canContinue.removeDuplicates().sink { enabled in
            if enabled { changes.append(port.now) }
        }
        defer { observation.cancel() }
        port.onEvent?(.reportedMode(.color))
        port.schedule(at: 10) { screen.select(.mono) }
        port.schedule(at: 15) { port.complete(.accepted) }
        port.schedule(at: 80) { port.onEvent?(.reportedMode(.color)) }
        port.schedule(at: 120) { port.onEvent?(.reportedMode(.mono)) }

        port.advance(to: 119)
        XCTAssertEqual(screen.reply, .accepted)
        XCTAssertEqual(screen.reportedMode, .color)
        XCTAssertFalse(screen.canContinue)
        port.advance(to: 120)
        XCTAssertTrue(screen.canContinue)
        XCTAssertEqual(screen.reportedMode, .mono)
        XCTAssertEqual(changes, [120])
        XCTAssertEqual(port.requests, [.mono])
    }

    @MainActor func testStateCanArriveBeforeSetCompletion() async {
        let port = ScriptedCamera()
        let screen = CameraScreen(camera: port)
        screen.select(.mono)
        port.onEvent?(.reportedMode(.mono))
        XCTAssertTrue(screen.canContinue)
        port.complete(.accepted)
        XCTAssertTrue(screen.canContinue)
        port.onEvent?(.reportedMode(.color))
        XCTAssertFalse(screen.canContinue)
    }

    @MainActor func testControlTimeoutDoesNotStopFramesOrRetryCommand() async {
        let port = ScriptedCamera()
        let screen = CameraScreen(camera: port)
        screen.select(.mono)
        port.complete(.timedOut)
        for id in 10...12 {
            port.onEvent?(.frame(id))
            XCTAssertEqual(screen.lastFrame, id)
        }
        XCTAssertEqual(screen.reply, .timedOut)
        XCTAssertFalse(screen.canContinue)
        XCTAssertEqual(port.requests, [.mono])
    }
}
