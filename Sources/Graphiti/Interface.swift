import GraphQL

public final class Interface<RootType : Keyable, Context, Reference : InterfaceReference> : Component<RootType, Context> {
    let name: String?
    let fields: [FieldComponent<Reference.InterfaceType, Reference.Keys, Context>]
    
    override func update(builder: SchemaBuilder) throws {
        let interfaceType = try GraphQLInterfaceType(
            name: name ?? Reflection.name(for: Reference.InterfaceType.self),
            description: description,
            fields: fields(provider: builder),
            resolveType: nil
        )

        try builder.map(Reference.InterfaceType.self, to: interfaceType)
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
        type: Reference.Type,
        name: String? = nil,
        fields: [FieldComponent<Reference.InterfaceType, Reference.Keys, Context>]
    )  {
        self.name = name
        self.fields = fields
    }
}
