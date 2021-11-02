import GraphQL
import NIO

#warning("TODO: Deal with schema composition. To do that we'll probably need to remove `Resolver` from Component? We'll need Resolvers for each type of operation, Query, Mutation and Subscription. The type of the Resolver will be defined in these Operations themselves, not in the schema.")
public final class Schema<Resolver, Context> {
    public let schema: GraphQLSchema

    internal init(
        coders: Coders,
        components: [Component<Resolver, Context>]
    ) throws {
        let typeProvider = SchemaTypeProvider()
        
        for component in components {
            try component.update(typeProvider: typeProvider, coders: coders)
        }
        
        guard let query = typeProvider.query else {
            throw GraphQLError(
                message: "Query type is required."
            )
        }
        
        self.schema = try GraphQLSchema(
            query: query,
            mutation: typeProvider.mutation,
            subscription: typeProvider.subscription,
            types: typeProvider.types,
            directives: typeProvider.directives
        )
    }
}

extension Schema: CustomDebugStringConvertible {
    public var debugDescription: String {
        printSchema(schema: schema)
    }
}

public extension Schema {
    convenience init(
        coders: Coders = Coders(),
        @ComponentBuilder<Resolver, Context> _ components: () -> Component<Resolver, Context>
    ) {
        try! self.init(
            coders: coders,
            components: [components()]
        )
    }
    
    convenience init(
        coders: Coders = Coders(),
        @ComponentBuilder<Resolver, Context> _ components: () -> [Component<Resolver, Context>]
    ) {
        try! self.init(
            coders: coders,
            components: components()
        )
    }
   
    @available(*, deprecated, message: "Use the function where the label for the eventLoopGroup parameter is namded `on`.")
    func execute(
        request: String,
        resolver: Resolver,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<GraphQLResult> {
        execute(
            request: request,
            resolver: resolver,
            context: context,
            on: eventLoopGroup,
            variables: variables,
            operationName: operationName
        )
    }

    @available(macOS 12, *)
    func execute(
            request: String,
            resolver: Resolver,
            context: Context,
            on eventLoopGroup: EventLoopGroup,
            variables: [String: Map] = [:],
            operationName: String? = nil
    ) async throws -> GraphQLResult {
        try await execute(
            request: request,
            resolver: resolver,
            context: context,
            on: eventLoopGroup,
            variables: variables,
            operationName: operationName
        ).get()
    }

    func execute(
        request: String,
        resolver: Resolver,
        context: Context,
        on eventLoopGroup: EventLoopGroup,
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
   
    @available(*, deprecated, message: "Use the function where the label for the eventLoopGroup parameter is named `on`.")
    func subscribe(
        request: String,
        resolver: Resolver,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<SubscriptionResult> {
        subscribe(
            request: request,
            resolver: resolver,
            context: context,
            on: eventLoopGroup,
            variables: variables,
            operationName: operationName
        )
    }

    @available(macOS 12, *)
    func subscribe(
            request: String,
            resolver: Resolver,
            context: Context,
            on eventLoopGroup: EventLoopGroup,
            variables: [String: Map] = [:],
            operationName: String? = nil
    ) async throws -> SubscriptionResult {
        try await self.subscribe(
            request: request,
            resolver: resolver,
            context: context,
            on: eventLoopGroup,
            variables: variables,
            operationName: operationName
        ).get()
    }

    func subscribe(
        request: String,
        resolver: Resolver,
        context: Context,
        on eventLoopGroup: EventLoopGroup,
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
