import GraphQL

final class SchemaTypeProvider: TypeProvider {
    var graphQLNameMap: [AnyType: String] = [
        AnyType(Int.self): "Int",
        AnyType(Double.self): "Float",
        AnyType(String.self): "String",
        AnyType(Bool.self): "Boolean",
    ]

    var graphQLTypeMap: [AnyType: GraphQLType] = [
        AnyType(Int.self): GraphQLInt,
        AnyType(Double.self): GraphQLFloat,
        AnyType(String.self): GraphQLString,
        AnyType(Bool.self): GraphQLBoolean,
    ]
    
    var federatedTypes: [GraphQLObjectType] = []
    var federatedSDL: String? = nil

    var query: GraphQLObjectType?
    var mutation: GraphQLObjectType?
    var subscription: GraphQLObjectType?
    var types: [GraphQLNamedType] = []
    var directives: [GraphQLDirective] = []

    func add(type: Any.Type, as graphQLType: GraphQLNamedType) throws {
        try map(type, to: graphQLType)
        types.append(graphQLType)
    }
}
