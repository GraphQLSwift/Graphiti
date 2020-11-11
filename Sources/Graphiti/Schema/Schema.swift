import GraphQL
import NIO

public final class Schema<Resolver, Context> {
    public let schema: GraphQLSchema

    public init(components: [Component<Resolver, Context>]) throws {
        let typeProvider = SchemaTypeProvider()
        
        for component in components {
            try component.update(typeProvider: typeProvider)
        }
        
        guard let query = typeProvider.query else {
            fatalError("Query type is required.")
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

public extension Schema {
    convenience init(@ComponentBuilder<Resolver, Context> _ components: () -> Component<Resolver, Context>) throws {
        try self.init(components: [components()])
    }
    
    convenience init(@ComponentBuilder<Resolver, Context> _ components: () -> [Component<Resolver, Context>]) throws {
        try self.init(components: components())
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
}
