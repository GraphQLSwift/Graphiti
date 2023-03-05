import Foundation
@testable import Graphiti
import GraphQL
import NIO
import XCTest

class ValidationRulesTests: XCTestCase {
    // Test registering custom validation rules
    func testRegisteringCustomValidationRule() throws {
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
            schema: testSchema,
            validationRules: GraphQL.specifiedRules + [disableIntrospectionValidation(context:)]
        )

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                  __type(name: "Query") {
                      name
                      description
                    }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
            GraphQLResult(errors: [
                .init(message: "GraphQL introspection is not allowed, but the query contained __schema or __type", locations: [.init(line: 2, column: 3)])
            ])
        )
    }
}


func disableIntrospectionValidation(context: ValidationContext) -> Visitor {
    return Visitor(enter: { node, _, _, _, _ in
        if let field = node as? GraphQL.Field, ["__schema", "__type"].contains(field.name.value) {
            context.report(error: .init(message: "GraphQL introspection is not allowed, but the query contained __schema or __type", nodes: [node]))
        }
        return .continue
    })
}

private class TestAPI<Resolver, ContextType>: API {
    public let resolver: Resolver
    public let schema: Schema<Resolver, ContextType>
    var validationRules: [(ValidationContext) -> Visitor]

    init(resolver: Resolver, schema: Schema<Resolver, ContextType>, validationRules: [(ValidationContext) -> Visitor]) {
        self.resolver = resolver
        self.schema = schema
        self.validationRules = validationRules
    }
}
