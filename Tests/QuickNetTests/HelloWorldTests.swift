import XCTest
@testable import QuickNet

final class QuickNetTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HelloWorld().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
