import GraphQL

public final class UnionTypeBuilder<Type> {
    public var description: String? = nil
    public var resolveType: GraphQLTypeResolve? = nil
    public var types: [Any.Type] = []
}

