@testable import Graphiti
import GraphQL
import XCTest

class DirectiveTests: XCTestCase {
    private let api = StarWarsAPI()

    func testSkip() async throws {
        let query = """
        query FetchHeroNameWithSkip($skipName: Boolean!) {
            hero {
                id
                name @skip(if: $skipName)
            }
        }
        """

        let input: [String: Map] = [
            "skipName": true,
        ]

        let response = try await api.execute(
            request: query,
            context: StarWarsContext(),
            variables: input
        )

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "id": "2001",
                ],
            ]
        )

        XCTAssertEqual(response, expected)
    }

    func testInclude() async throws {
        let query = """
        query FetchHeroNameWithSkip($includeName: Boolean!) {
            hero {
                id
                name @include(if: $includeName)
            }
        }
        """

        let input: [String: Map] = [
            "includeName": false,
        ]

        let response = try await api.execute(
            request: query,
            context: StarWarsContext(),
            variables: input
        )

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "id": "2001",
                ],
            ]
        )

        XCTAssertEqual(response, expected)
    }

    func testOneOfAcceptsGoodValue() async throws {
        let result = try await OneOfAPI().execute(
            request: """
            query {
                test(input: {a: "abc"}) {
                    a
                    b
                }
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "test": [
                        "a": "abc",
                        "b": .null,
                    ],
                ]
            )
        )
    }

    func testOneOfRejectsBadValue() async throws {
        let result = try await OneOfAPI().execute(
            request: """
            query {
                test(input: {a: "abc", b: 123}) {
                    a
                    b
                }
            }
            """,
            context: NoContext()
        )
        XCTAssertEqual(
            result.errors[0].message,
            #"OneOf Input Object "TestInputObject" must specify exactly one key."#
        )
    }

    struct OneOfAPI: API {
        struct TestObject: Codable {
            let a: String?
            let b: Int?
        }

        struct TestInputObject: Codable {
            let a: String?
            let b: Int?
        }

        struct TestArguments: Codable {
            let input: TestInputObject
        }

        struct OneOfResolver {
            func test(context _: NoContext, arguments: TestArguments) -> TestObject {
                return TestObject(a: arguments.input.a, b: arguments.input.b)
            }
        }

        let resolver = OneOfResolver()

        let schema = try! Schema<OneOfResolver, NoContext> {
            Type(TestObject.self) {
                Field("a", at: \.a)
                Field("b", at: \.b)
            }

            Input(TestInputObject.self, isOneOf: true) {
                InputField("a", at: \.a)
                InputField("b", at: \.b)
            }

            Query {
                Field("test", at: OneOfResolver.test) {
                    Argument("input", at: \.input)
                }
            }
        }
    }
}
