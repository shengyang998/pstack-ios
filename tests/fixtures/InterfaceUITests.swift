import XCTest

final class InterfaceUITests: XCTestCase {
    func testOnlyStateReportEnablesNextButton() {
        let app = XCUIApplication()
        app.launch()
        let next = app.buttons["Next"]
        XCTAssertFalse(next.isEnabled)
        app.buttons["Switch mode"].tap()
        app.buttons["Deliver command reply"].tap()
        XCTAssertFalse(next.isEnabled)
        app.buttons["Deliver old state"].tap()
        XCTAssertFalse(next.isEnabled)
        app.buttons["Deliver target state"].tap()
        XCTAssertTrue(next.isEnabled)
        next.tap()
        XCTAssertTrue(app.staticTexts["Advanced"].exists)
    }
}
