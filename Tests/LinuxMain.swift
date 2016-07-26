import XCTest
@testable import RedbirdTestSuite

XCTMain([
	testCase(ConversionTests.allTests),
	testCase(FormattingTests.allTests),
	testCase(ParsingTests.allTests),
	testCase(PerformanceTests.allTests),
	testCase(RedbirdTests.allTests),
	testCase(StringTests.allTests)
])
