import GraphQL
import NIO

public typealias NoContext = Void

public class SchemaComponent<RootType : FieldKeyProvider, Context> : Descriptable {
    var description: String? = nil
    
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    func update(schema: SchemaThingy) {}
}

final class SchemaThingy : TypeProvider {
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

private final class MergerSchemaComponent<RootType : FieldKeyProvider, Context> : SchemaComponent<RootType, Context> {
    let components: [SchemaComponent<RootType, Context>]
    
    init(components: [SchemaComponent<RootType, Context>]) {
        self.components = components
    }
    
    override func update(schema: SchemaThingy) {
        for component in self.components {
            component.update(schema: schema)
        }
    }
}

@_functionBuilder
public struct SchemaBuilder<RootType : FieldKeyProvider, Context> {
    public static func buildBlock(_ components: SchemaComponent<RootType, Context>...) -> SchemaComponent<RootType, Context> {
        return MergerSchemaComponent(components: components)
    }
}

public final class Schema<RootType : FieldKeyProvider, Context> {
    private let schema: GraphQLSchema

    public init(@SchemaBuilder<RootType, Context> component: () -> SchemaComponent<RootType, Context>) {
        let component = component()
        let thingy = SchemaThingy()
        component.update(schema: thingy)
        
        guard let query = thingy.query else {
            fatalError("Query type is required.")
        }
        
        self.schema = try! GraphQLSchema(
            query: query,
            mutation: thingy.mutation,
            subscription: thingy.subscription,
            types: thingy.types,
            directives: thingy.directives
        )
    }
}

extension Schema {
    public func execute(
        request: String,
        root: RootType,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> Future<GraphQLResult> {
        do {
            return try graphql(
                schema: self.schema,
                request: request,
                rootValue: root,
                context: context,
                eventLoopGroup: eventLoopGroup,
                variableValues: variables,
                operationName: operationName
            )
        } catch {
            return eventLoopGroup.next().newFailedFuture(error: error)
        }
    }
}
