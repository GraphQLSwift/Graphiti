import XCTest
@testable import Graphiti

class HelloWorldTests : XCTestCase {
    let schema = try! Schema<Void> { schema in
        try schema.query { query in
            try query.field(name: "hello", type: String.self) { _ in
                "world"
            }
        }
    }

    func testHello() throws {
        let query = "{ hello }"
        let expected: Map = [
            "data": [
                "hello": "world"
            ]
        ]
        let result = try schema.execute(request: query)
        XCTAssertEqual(result, expected)
    }

    func testBoyhowdy() throws {
        let query = "{ boyhowdy }"

        let expectedErrors: Map = [
            "errors": [
                [
                    "message": "Cannot query field \"boyhowdy\" on type \"Query\".",
                    "locations": [["line": 1, "column": 3]]
                ]
            ]
        ]

        let result = try schema.execute(request: query)
        XCTAssertEqual(result, expectedErrors)
    }
}

extension HelloWorldTests {
    static var allTests: [(String, (HelloWorldTests) -> () throws -> Void)] {
        return [
            ("testHello", testHello),
            ("testBoyhowdy", testBoyhowdy),
        ]
    }
}
