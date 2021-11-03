import XCTest
@testable import GraphitiTests

XCTMain([
    testCase(CounterTests.allTests),
    testCase(HelloWorldTests.allTests),
    testCase(StarWarsQueryTests.allTests),
    testCase(StarWarsIntrospectionTests.allTests),
    testCase(ScalarTests.allTests),
])
