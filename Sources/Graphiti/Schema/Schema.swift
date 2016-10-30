import GraphQL

public final class SchemaBuilder<Root> {
    public var query: ObjectType<Root>?
    public var mutation: ObjectType<Root>? = nil
    public var subscription: ObjectType<Root>? = nil
    var types: [GraphQLNamedType] = []
    var directives: [GraphQLDirective] = []
}

public struct Schema<Root> {
    let schema: GraphQLSchema

    public init(_ build: (SchemaBuilder<Root>) throws -> Void) throws {
        let builder = SchemaBuilder<Root>()
        try build(builder)

        guard let query = builder.query else {
            throw GraphQLError(
                message: "Query type is required."
            )
        }

        schema = try GraphQLSchema(
            query: query.objectType,
            mutation: builder.mutation?.objectType,
            subscription: builder.subscription?.objectType,
            types: builder.types,
            directives: builder.directives
        )
    }

    public func execute(
        request: String,
        contextValue: Any = Void(),
        variableValues: [String: Map] = [:],
        operationName: String? = nil
        ) throws -> Map {
        return try graphql(
            schema: schema,
            request: request,
            contextValue: contextValue,
            variableValues: variableValues,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        rootValue: Root,
        contextValue: Any = Void(),
        variableValues: [String: Map] = [:],
        operationName: String? = nil
        ) throws -> Map {
        return try graphql(
            schema: schema,
            request: request,
            rootValue: rootValue,
            contextValue: contextValue,
            variableValues: variableValues,
            operationName: operationName
        )
    }
}
