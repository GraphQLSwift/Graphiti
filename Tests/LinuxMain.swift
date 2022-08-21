@testable import GraphitiTests
import XCTest

XCTMain([
    testCase(HelloWorldTests.allTests),
    testCase(StarWarsQueryTests.allTests),
    testCase(StarWarsIntrospectionTests.allTests),
])
