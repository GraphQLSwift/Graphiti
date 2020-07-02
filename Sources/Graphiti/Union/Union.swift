import GraphQL

public final class Union<Root : Keyable, Context, UnionType> : Component<Root, Context> {
    private let members: [Any.Type]
    
    override func update(builder: SchemaBuilder) throws {
        let unionType = try GraphQLUnionType(
            name: name,
            description: description,
            resolveType: nil,
            types: members.map {
                try builder.getObjectType(from: $0)
            }
        )
        
        try builder.map(UnionType.self, to: unionType)
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
