import XCTest
@testable import GraphitiTests

XCTMain([
    testCase(HelloWorldTests.allTests),
    testCase(StarWarsQueryTests.allTests),
    testCase(StarWarsIntrospectionTests.allTests),
])
