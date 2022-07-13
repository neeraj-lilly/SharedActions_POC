import XCTest
@testable import check_pod_integrity

final class check_pod_integrityTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(check_pod_integrity().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
