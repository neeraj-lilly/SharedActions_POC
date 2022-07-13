import XCTest

import check_pod_integrityTests

var tests = [XCTestCaseEntry]()
tests += check_pod_integrityTests.allTests()
XCTMain(tests)
