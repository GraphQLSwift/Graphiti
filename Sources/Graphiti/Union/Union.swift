import GraphQL

public final class Union<Resolver, Context, UnionType> : Component<Resolver, Context> {
    private let members: [Any.Type]
    
    override func update(typeProvider: SchemaTypeProvider) throws {
        let unionType = try GraphQLUnionType(
            name: name,
            description: description,
            resolveType: nil,
            types: members.map {
                try typeProvider.getObjectType(from: $0)
            }
        )
        
        try typeProvider.map(UnionType.self, to: unionType)
    }
    
    init(
        type: UnionType.Type,
        name: String? = nil,
        members: [Any.Type]
    ) {
        self.members = members
        super.init(name: name ?? Reflection.name(for: UnionType.self))
        
    }
}

public extension Union {
    convenience init(
        _ type: UnionType.Type,
        as name: String? = nil,
        members: Any.Type...
    ) {
        self.init(type: type, name: name, members: members)
    }
}
