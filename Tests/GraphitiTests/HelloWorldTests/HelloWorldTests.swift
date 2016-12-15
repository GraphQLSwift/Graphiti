import XCTest
@testable import Graphiti
import GraphQL

extension Float : InputType, OutputType {
    public init(map: Map) throws {
        self.init(try map.asDouble())
    }

    public func asMap() throws -> Map {
        return .double(Double(self))
    }
}

class HelloWorldTests : XCTestCase {
    let schema = try! Schema<NoRoot, NoContext> { schema in
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

    func testScalar() throws {
        let schema = try Schema<NoRoot, NoContext> { schema in
            try schema.scalar(type: Float.self) { scalar in
                scalar.description = "The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)."

                scalar.parseValue { value in
                    if case .double = value {
                        return value
                    }

                    if case .int(let int) = value {
                        return .double(Double(int))
                    }

                    return .null
                }

                scalar.parseLiteral { ast in
                    if let ast = ast as? FloatValue, let double = Double(ast.value) {
                        return .double(double)
                    }

                    if let ast = ast as? IntValue, let double = Double(ast.value) {
                        return .double(double)
                    }

                    return .null
                }
            }

            try schema.query { query in
                struct FloatArguments : Arguments {
                    let float: Float
                }

                try query.field(name: "float", type: Float.self) { (_, arguments: FloatArguments, _, _) in
                    return arguments.float
                }
            }
        }

        var query: String
        let expected: Map = ["data": ["float": 4.0]]
        var result: Map

        query = "query Query($float: Float!) { float(float: $float) }"
        result = try schema.execute(request: query, variables: ["float": 4])
        XCTAssertEqual(result, expected)

        query = "query Query { float(float: 4) }"
        result = try schema.execute(request: query)
        XCTAssertEqual(result, expected)
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
