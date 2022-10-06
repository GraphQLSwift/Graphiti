import Foundation
@testable import Graphiti
import GraphQL
import NIO
import XCTest

class SchemaTests: XCTestCase {
    // Tests that circularly dependent objects can be used in schema and resolved correctly
    func testCircularDependencies() throws {
        struct A: Codable {
            let name: String
            var b: B {
                B(name: name)
            }
        }

        struct B: Codable {
            let name: String
            var a: A {
                A(name: name)
            }
        }

        struct TestResolver {
            func a(context _: NoContext, arguments _: NoArguments) -> A {
                return A(name: "Circular")
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Type(A.self) {
                Field("name", at: \.name)
                Field("b", at: \.b)
            }
            Type(B.self) {
                Field("name", at: \.name)
                Field("a", at: \.a)
            }
            Query {
                Field("a", at: TestResolver.a)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                  a {
                    b {
                      name
                    }
                  }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "a": [
                    "b": [
                        "name": "Circular",
                    ],
                ],
            ])
        )
    }
}

private class TestAPI<Resolver, ContextType>: API {
    public let resolver: Resolver
    public let schema: Schema<Resolver, ContextType>

    init(resolver: Resolver, schema: Schema<Resolver, ContextType>) {
        self.resolver = resolver
        self.schema = schema
    }
}
