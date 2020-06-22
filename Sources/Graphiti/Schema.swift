import GraphQL
import NIO

final class SchemaBuilder : TypeProvider {
    var graphQLTypeMap: [AnyType: GraphQLType] = [
        AnyType(Int.self): GraphQLInt,
        AnyType(Double.self): GraphQLFloat,
        AnyType(String.self): GraphQLString,
        AnyType(Bool.self): GraphQLBoolean,
    ]
    
    var query: GraphQLObjectType? = nil
    var mutation: GraphQLObjectType? = nil
    var subscription: GraphQLObjectType? = nil
    var types: [GraphQLNamedType] = []
    var directives: [GraphQLDirective] = []
}

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
    
    public convenience init(
        build: (ComponentsInitializer<RootType, Context>) -> Void
    ) throws {
        let initializer = ComponentsInitializer<RootType, Context>()
        build(initializer)
        try self.init(components: initializer.components)
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
