import GraphQL
import NIO

public final class Schema<RootType : Keyable, Context> {
    public let schema: GraphQLSchema

    private init(components: [Component<RootType, Context>]) throws {
        let builder = SchemaBuilder()
        
        for component in components {
            try component.update(builder: builder)
        }
        
        guard let query = builder.query else {
            fatalError("Query type is required.")
        }
        
        self.schema = try GraphQLSchema(
            query: query,
            mutation: builder.mutation,
            subscription: builder.subscription,
            types: builder.types,
            directives: builder.directives
        )
    }
    
    public convenience init(_ components: Component<RootType, Context>...) throws {
        try self.init(components: components)
    }
    
    public func execute(
        request: String,
        root: RootType,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<GraphQLResult> {
        do {
            return try graphql(
                schema: schema,
                request: request,
                rootValue: root,
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
