import GraphQL

public final class Union<Root : FieldKeyProvider, Context, UnionType> : SchemaComponent<Root, Context> {
    private let name: String?
    private let members: [Any.Type]
    
    override func update(schema: SchemaThingy) {
        let unionType = try! GraphQLUnionType(
            name: self.name ?? fixName(String(describing: UnionType.self)),
            description: self.description,
            resolveType: nil,
            types: self.members.map {
                try! schema.getObjectType(from: $0)
            }
        )
        
        try! schema.map(UnionType.self, to: unionType)
    }
    
    public init(
        _ type: UnionType.Type,
        name: String? = nil,
        members: Any.Type...
    ) {
        self.name = name
        self.members = members
    }
}
