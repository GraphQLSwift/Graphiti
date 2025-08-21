import Graphiti
import GraphQL
import XCTest

class DefaultValueTests: XCTestCase {
    func testBoolDefault() async throws {
        let result = try await DefaultValueAPI().execute(
            request: """
            {
                bool
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: ["bool": true])
        )
    }

    func testIntDefault() async throws {
        let result = try await DefaultValueAPI().execute(
            request: """
            {
                int
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: ["int": 1])
        )
    }

    func testFloatDefault() async throws {
        let result = try await DefaultValueAPI().execute(
            request: """
            {
                float
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: ["float": 1.1])
        )
    }

    func testStringDefault() async throws {
        let result = try await DefaultValueAPI().execute(
            request: """
            {
                string
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: ["string": "hello"])
        )
    }

    func testEnumDefault() async throws {
        let result = try await DefaultValueAPI().execute(
            request: """
            {
                enum
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: ["enum": "valueA"])
        )
    }

    func testArrayDefault() async throws {
        let result = try await DefaultValueAPI().execute(
            request: """
            {
                array
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: ["array": ["a", "b", "c"]])
        )
    }

    func testInputDefault() async throws {
        // Test input object argument default
        var result = try await DefaultValueAPI().execute(
            request: """
            {
                input {
                bool
                int
                float
                string
                enum
                array
                }
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: [
                "input": [
                    "bool": true,
                    "int": 1,
                    "float": 1.1,
                    "string": "hello",
                    "enum": "valueA",
                    "array": ["a", "b", "c"],
                ],
            ])
        )

        // Test input object field defaults
        result = try await DefaultValueAPI().execute(
            request: """
            {
                input(input: {bool: true}) {
                bool
                int
                float
                string
                enum
                array
                }
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            .init(data: [
                "input": [
                    "bool": true,
                    "int": 1,
                    "float": 1.1,
                    "string": "hello",
                    "enum": "valueA",
                    "array": ["a", "b", "c"],
                ],
            ])
        )
    }
}

struct DefaultValueAPI: API {
    typealias ContextType = NoContext
    struct Resolver {
        struct BoolArgs: Codable {
            let bool: Bool
        }

        func bool(context _: NoContext, arguments: BoolArgs) -> Bool {
            return arguments.bool
        }

        struct IntArgs: Codable {
            let int: Int
        }

        func int(context _: NoContext, arguments: IntArgs) -> Int {
            return arguments.int
        }

        struct FloatArgs: Codable {
            let float: Double
        }

        func float(context _: NoContext, arguments: FloatArgs) -> Double {
            return arguments.float
        }

        struct StringArgs: Codable {
            let string: String
        }

        func string(context _: NoContext, arguments: StringArgs) -> String {
            return arguments.string
        }

        struct EnumArgs: Codable {
            let `enum`: DefaultEnum
        }

        func `enum`(context _: NoContext, arguments: EnumArgs) -> DefaultEnum {
            return arguments.enum
        }

        struct ArrayArgs: Codable {
            let array: [String]
        }

        func array(context _: NoContext, arguments: ArrayArgs) -> [String] {
            return arguments.array
        }

        struct InputArgs: Codable {
            let input: DefaultInputType
        }

        func input(context _: NoContext, arguments: InputArgs) -> DefaultOutputType {
            return .init(
                bool: arguments.input.bool,
                int: arguments.input.int,
                float: arguments.input.float,
                string: arguments.input.string,
                enum: arguments.input.enum,
                array: arguments.input.array
            )
        }
    }

    let resolver = Resolver()

    let schema = try! Schema<Resolver, NoContext> {
        Enum(DefaultEnum.self) {
            Value(.valueA)
            Value(.valueB)
        }

        Input(DefaultInputType.self) {
            InputField("bool", at: \.bool).defaultValue(true)
            InputField("int", at: \.int).defaultValue(1)
            InputField("float", at: \.float).defaultValue(1.1)
            InputField("string", at: \.string).defaultValue("hello")
            InputField("enum", at: \.`enum`).defaultValue(.valueA)
            InputField("array", at: \.array).defaultValue(["a", "b", "c"])
        }

        Type(DefaultOutputType.self) {
            Field("bool", at: \.bool)
            Field("int", at: \.int)
            Field("float", at: \.float)
            Field("string", at: \.string)
            Field("enum", at: \.`enum`)
            Field("array", at: \.array)
        }

        Query {
            Field("bool", at: Resolver.bool) {
                Argument("bool", at: \.bool).defaultValue(true)
            }
            Field("int", at: Resolver.int) {
                Argument("int", at: \.int).defaultValue(1)
            }
            Field("float", at: Resolver.float) {
                Argument("float", at: \.float).defaultValue(1.1)
            }
            Field("string", at: Resolver.string) {
                Argument("string", at: \.string).defaultValue("hello")
            }
            Field("enum", at: Resolver.enum) {
                Argument("enum", at: \.enum).defaultValue(.valueA)
            }
            Field("array", at: Resolver.array) {
                Argument("array", at: \.array).defaultValue(["a", "b", "c"])
            }
            Field("input", at: Resolver.input) {
                Argument("input", at: \.input).defaultValue(.init(
                    bool: true,
                    int: 1,
                    float: 1.1,
                    string: "hello",
                    enum: .valueA,
                    array: ["a", "b", "c"]
                ))
            }
        }
    }

    enum DefaultEnum: String, Codable {
        case valueA
        case valueB
    }

    struct DefaultInputType: Codable {
        let bool: Bool
        let int: Int
        let float: Double
        let string: String
        let `enum`: DefaultEnum
        let array: [String]
    }

    struct DefaultOutputType: Codable {
        let bool: Bool
        let int: Int
        let float: Double
        let string: String
        let `enum`: DefaultEnum
        let array: [String]
    }
}
