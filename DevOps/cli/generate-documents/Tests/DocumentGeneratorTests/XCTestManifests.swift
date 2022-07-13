import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(generate_document_exampleTests.allTests),
    ]
}
#endif
