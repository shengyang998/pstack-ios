import XCTest

final class CounterUITests: XCTestCase {
    func testTapChangesCount() {
        let app = XCUIApplication()
        app.launch()
        let count = app.staticTexts["count"]
        XCTAssertEqual(count.label, "0")
        app.buttons["increment"].tap()
        XCTAssertEqual(count.label, "1")
    }
}
