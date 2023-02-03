import GraphQL
import NIO

public final class Schema<Resolver, Context> {
    public let schema: GraphQLSchema

    init(
        coders: Coders,
        components: [Component<Resolver, Context>]
    ) throws {
        let typeProvider = SchemaTypeProvider()

        // Collect types mappings first
        for component in components {
            try component.setGraphQLName(typeProvider: typeProvider)
        }

        // Order component by componentType build order
        let sortedComponents = components.sorted {
            $0.componentType.buildOrder <= $1.componentType.buildOrder
        }
        for component in sortedComponents {
            try component.update(typeProvider: typeProvider, coders: coders)
        }

        guard let query = typeProvider.query else {
            fatalError("Query type is required.")
        }

        schema = try GraphQLSchema(
            query: query,
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
        @ComponentBuilder<Resolver, Context> _ components: () -> Component<Resolver, Context>
    ) throws {
        try self.init(
            coders: coders,
            components: [components()]
        )
    }

    convenience init(
        coders: Coders = Coders(),
        @ComponentBuilder<Resolver, Context> _ components: () -> [Component<Resolver, Context>]
    ) throws {
        try self.init(
            coders: coders,
            components: components()
        )
    }

    func execute(
        request: String,
        resolver: Resolver,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<GraphQLResult> {
        do {
            return try graphql(
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
        operationName: String? = nil
    ) -> EventLoopFuture<SubscriptionResult> {
        do {
            return try graphqlSubscribe(
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
