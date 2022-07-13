import XCTest

import generate_document_exampleTests

var tests = [XCTestCaseEntry]()
tests += generate_document_exampleTests.allTests()
XCTMain(tests)
