import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(UserTests.allTests),
        testCase(NetworkTests.allTests),
        testCase(AccessTokenTests.allTests),
    ]
}
#endif
