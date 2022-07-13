import XCTest
@testable import ArchiveRelease

final class ArchiveReleaseTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ArchiveRelease().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
