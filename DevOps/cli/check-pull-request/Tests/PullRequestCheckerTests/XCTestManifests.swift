import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(check_pod_integrityTests.allTests),
    ]
}
#endif
