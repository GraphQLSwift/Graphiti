import GraphQL
import NIO

public struct SchemaError: Error, Equatable {
    let description: String
}

public final class Schema<Resolver, Context> {
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
            throw SchemaError(description: "Schema must contain at least 1 query or federated resolver")
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
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) -> EventLoopFuture<GraphQLResult> {
        do {
            return try graphql(
                validationRules: GraphQL.specifiedRules + validationRules,
                schema: schema,
                request: request,
                rootValue: resolver,
                context: context,
                eventLoopGroup: eventLoopGroup,
                variableValues: variables,
                operationName: operationName
            )
        } catch {
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }

    func subscribe(
        request: String,
        resolver: Resolver,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [(ValidationContext) -> Visitor] = []
    ) -> EventLoopFuture<SubscriptionResult> {
        do {
            return try graphqlSubscribe(
                validationRules: GraphQL.specifiedRules + validationRules,
                schema: schema,
                request: request,
                rootValue: resolver,
                context: context,
                eventLoopGroup: eventLoopGroup,
                variableValues: variables,
                operationName: operationName
            )
        } catch {
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}
