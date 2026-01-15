import GraphQL

public struct SchemaError: Error, Equatable {
    let description: String
}

public final class Schema<Resolver: Sendable, Context: Sendable>: Sendable {
    public let schema: GraphQLSchema

    init(
        coders: Coders,
        federatedSDL: String?,
        components: [Component<Resolver, Context>]
    ) throws {
        let typeProvider = SchemaTypeProvider()
        typeProvider.federatedSDL = federatedSDL

        for component in components {
            try component.update(typeProvider: typeProvider, coders: coders)
        }

        guard typeProvider.query != nil || !typeProvider.federatedResolvers.isEmpty else {
            throw SchemaError(
                description: "Schema must contain at least 1 query or federated resolver"
            )
        }

        schema = try GraphQLSchema(
            query: typeProvider.query,
            mutation: typeProvider.mutation,
            subscription: typeProvider.subscription,
            types: typeProvider.types,
            directives: typeProvider.directives
        )
    }
}

public extension Schema {
    convenience init(
        coders: Coders = Coders(),
        federatedSDL: String? = nil,
        @ComponentBuilder<Resolver, Context> _ components: () -> Component<Resolver, Context>
    ) throws {
        try self.init(
            coders: coders,
            federatedSDL: federatedSDL,
            components: [components()]
        )
    }

    convenience init(
        coders: Coders = Coders(),
        federatedSDL: String? = nil,
        @ComponentBuilder<Resolver, Context> _ components: () -> [Component<Resolver, Context>]
    ) throws {
        try self.init(
            coders: coders,
            federatedSDL: federatedSDL,
            components: components()
        )
    }

    func execute(
        request: String,
        resolver: Resolver,
        context: Context,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [@Sendable (ValidationContext) -> Visitor] = []
    ) async throws -> GraphQLResult {
        return try await graphql(
            schema: schema,
            request: request,
            rootValue: resolver,
            context: context,
            variableValues: variables,
            operationName: operationName,
            validationRules: GraphQL.specifiedRules + validationRules
        )
    }

    func subscribe(
        request: String,
        resolver: Resolver,
        context: Context,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [@Sendable (ValidationContext) -> Visitor] = []
    ) async throws -> Result<AsyncThrowingStream<GraphQLResult, Error>, GraphQLErrors> {
        return try await graphqlSubscribe(
            schema: schema,
            request: request,
            rootValue: resolver,
            context: context,
            variableValues: variables,
            operationName: operationName,
            validationRules: GraphQL.specifiedRules + validationRules
        )
    }
}
