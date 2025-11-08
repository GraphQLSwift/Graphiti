import Foundation
@testable import Graphiti
import GraphQL
import Testing

struct SchemaTests {
    // Tests that circularly dependent objects can be used in schema and resolved correctly
    @Test func circularDependencies() async throws {
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

        let result = try await api.execute(
            request: """
            query {
                a {
                b {
                    name
                }
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "a": [
                        "b": [
                            "name": "Circular",
                        ],
                    ],
                ])
        )
    }

    // Tests that we can resolve type references for named types
    @Test func typeReferenceForNamedType() async throws {
        struct LocationObject: Codable {
            let id: String
            let name: String
        }

        struct User: Codable {
            let id: String
            let location: LocationObject?
        }

        struct TestResolver {
            func user(context _: NoContext, arguments _: NoArguments) -> User {
                return User(
                    id: "user1",
                    location: LocationObject(
                        id: "location1",
                        name: "Earth"
                    )
                )
            }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Type(User.self) {
                Field("id", at: \.id)
                Field("location", at: \.location)
            }
            Type(LocationObject.self, as: "Location") {
                Field("id", at: \.id)
                Field("name", at: \.name)
            }
            Query {
                Field("user", at: TestResolver.user)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                user {
                location {
                    name
                }
                }
            }
            """,
            context: NoContext()
        )
        #expect(
            result ==
                GraphQLResult(data: [
                    "user": [
                        "location": [
                            "name": "Earth",
                        ],
                    ],
                ])
        )
    }

    @Test func schemaWithNoQuery() {
        struct User: Codable {
            let id: String
        }

        struct TestResolver {}

        do {
            _ = try Schema<TestResolver, NoContext> {
                Type(User.self) {
                    Field("id", at: \.id)
                }
            }
        } catch {
            #expect(
                error as? SchemaError ==
                    SchemaError(
                        description: "Schema must contain at least 1 query or federated resolver"
                    )
            )
        }
    }
}

private class TestAPI<Resolver: Sendable, ContextType: Sendable>: API {
    public let resolver: Resolver
    public let schema: Schema<Resolver, ContextType>

    init(resolver: Resolver, schema: Schema<Resolver, ContextType>) {
        self.resolver = resolver
        self.schema = schema
    }
}
