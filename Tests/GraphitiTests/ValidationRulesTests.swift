import Foundation
@testable import Graphiti
import GraphQL
import Testing

struct ValidationRulesTests {
    // Test registering custom validation rules
    @Test func registeringCustomValidationRule() async throws {
        struct TestResolver {
            var helloWorld: String { "Hellow World" }
        }

        let testSchema = try Schema<TestResolver, NoContext> {
            Query {
                Field("helloWorld", at: \.helloWorld)
            }
        }
        let api = TestAPI<TestResolver, NoContext>(
            resolver: TestResolver(),
            schema: testSchema
        )

        let result = try await api.execute(
            request: """
            query {
                __type(name: "Query") {
                    name
                    description
                }
            }
            """,
            context: NoContext(),
            validationRules: [NoIntrospectionRule]
        )
        #expect(
            result ==
                GraphQLResult(errors: [
                    .init(
                        message: "GraphQL introspection is not allowed, but the query contained __schema or __type",
                        locations: [.init(line: 2, column: 3)]
                    ),
                ])
        )
    }
}

private class TestAPI<Resolver: Sendable, ContextType: Sendable>: API {
    let resolver: Resolver
    let schema: Schema<Resolver, ContextType>

    init(resolver: Resolver, schema: Schema<Resolver, ContextType>) {
        self.resolver = resolver
        self.schema = schema
    }
}
