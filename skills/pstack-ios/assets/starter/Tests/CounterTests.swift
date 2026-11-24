import XCTest
@testable import PStackStarter

final class CounterTests: XCTestCase {
    func testTwoIncrementsAccumulate() {
        var counter = Counter()
        counter.increment()
        counter.increment()
        XCTAssertEqual(counter.value, 2)
    }
}
