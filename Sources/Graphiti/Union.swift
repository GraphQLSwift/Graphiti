import GraphQL

public final class Union<Root : Keyable, Context, UnionType> : Component<Root, Context> {
    private let name: String?
    private let members: [Any.Type]
    
    override func update(builder: SchemaBuilder) throws {
        let unionType = try GraphQLUnionType(
            name: name ?? Reflection.name(for: UnionType.self),
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
        self.name = name
        self.members = members
    }
}
