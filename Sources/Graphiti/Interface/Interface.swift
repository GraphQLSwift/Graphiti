import GraphQL

public final class Interface<RootType, Context, InterfaceType> : Component<RootType, Context> {
    let fields: [FieldComponent<InterfaceType, Context>]
    
    override func update(builder: SchemaBuilder) throws {
        let interfaceType = try GraphQLInterfaceType(
            name: name,
            description: description,
            fields: fields(provider: builder),
            resolveType: nil
        )

        try builder.map(InterfaceType.self, to: interfaceType)
    }
    
    func fields(provider: TypeProvider) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(provider: provider)
            map[name] = field
        }
        
        return map
    }
    
    init(
        type: InterfaceType.Type,
        name: String? = nil,
        fields: [FieldComponent<InterfaceType, Context>]
    )  {
        self.fields = fields
        super.init(name: name ?? Reflection.name(for: InterfaceType.self))
    }
}

public extension Interface {
    convenience init(
        _ type: InterfaceType.Type,
        as name: String? = nil,
        _ fields: FieldComponent<InterfaceType, Context>...
    ) {
        self.init(
            type: type,
            name: name,
            fields: fields
        )
    }
}
