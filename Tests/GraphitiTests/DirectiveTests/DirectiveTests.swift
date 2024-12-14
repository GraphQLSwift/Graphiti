@testable import Graphiti
import GraphQL
import NIO
import XCTest

class DirectiveTests: XCTestCase {
    private let api = StarWarsAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? self.group.syncShutdownGracefully()
    }

    func testSkip() throws {
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

        let response = try api.execute(
            request: query,
            context: StarWarsContext(),
            on: group,
            variables: input
        ).wait()

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "id": "2001",
                ],
            ]
        )

        XCTAssertEqual(response, expected)
    }

    func testInclude() throws {
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

        let response = try api.execute(
            request: query,
            context: StarWarsContext(),
            on: group,
            variables: input
        ).wait()

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "id": "2001",
                ],
            ]
        )

        XCTAssertEqual(response, expected)
    }

    func testOneOfAcceptsGoodValue() throws {
        try XCTAssertEqual(
            OneOfAPI().execute(
                request: """
                query {
                    test(input: {a: "abc"}) {
                        a
                        b
                    }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
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

    func testOneOfRejectsBadValue() throws {
        try XCTAssertEqual(
            OneOfAPI().execute(
                request: """
                query {
                    test(input: {a: "abc", b: 123}) {
                        a
                        b
                    }
                }
                """,
                context: NoContext(),
                on: group
            ).wait().errors[0].message,
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
