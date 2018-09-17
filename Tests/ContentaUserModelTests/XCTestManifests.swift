import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(UserTests.allTests),
        testCase(NetworkTest.allTests),
    ]
}
#endif
