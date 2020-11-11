import GraphQL

public final class Input<Resolver, Context, InputObjectType : Decodable> : Component<Resolver, Context> {
    let fields: [InputFieldComponent<InputObjectType, Context>]
    
    override func update(typeProvider: SchemaTypeProvider) throws {
        let inputObjectType = try GraphQLInputObjectType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider)
        )
        
        try typeProvider.map(InputObjectType.self, to: inputObjectType)
    }
    
    func fields(typeProvider: TypeProvider) throws -> InputObjectConfigFieldMap {
        var map: InputObjectConfigFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider)
            map[name] = field
        }
        
        return map
    }
    
    public init(
        type: InputObjectType.Type,
        name: String? = nil,
        fields: [InputFieldComponent<InputObjectType, Context>]
    ) {
        self.fields = fields
        super.init(name: name  ?? Reflection.name(for: InputObjectType.self))
    }
}

public extension Input {
    convenience init(
        _ type: InputObjectType.Type,
        as name: String? = nil,
        @InputFieldComponentBuilder<InputObjectType, Context> _ fields: () -> InputFieldComponent<InputObjectType, Context>
    ) {
        self.init(type: type, name: name, fields: [fields()])
    }
    
    convenience init(
        _ type: InputObjectType.Type,
        as name: String? = nil,
        @InputFieldComponentBuilder<InputObjectType, Context> _ fields: () -> [InputFieldComponent<InputObjectType, Context>]
    ) {
        self.init(type: type, name: name, fields: fields())
    }
}
