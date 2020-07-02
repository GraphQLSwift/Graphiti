import GraphQL

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
