import XCTest

import ContentaUserModelTests

var tests = [XCTestCaseEntry]()
tests += UserTests.allTests()
tests += NetworkTests.allTests()
XCTMain(tests)
