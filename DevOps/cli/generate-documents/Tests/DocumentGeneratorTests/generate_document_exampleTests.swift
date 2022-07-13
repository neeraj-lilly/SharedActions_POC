import XCTest
@testable import generate_document_example

final class generate_document_exampleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(generate_document_example().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
