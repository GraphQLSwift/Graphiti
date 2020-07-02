import GraphQL

public final class Input<RootType : Keyable, Context, InputObjectType : Decodable & Keyable> : Component<RootType, Context> {
    let fields: [InputFieldComponent<InputObjectType, InputObjectType.Keys, Context>]
    
    override func update(builder: SchemaBuilder) throws {
        let inputObjectType = try GraphQLInputObjectType(
            name: name,
            description: description,
            fields: fields(provider: builder)
        )
        
        try builder.map(InputObjectType.self, to: inputObjectType)
    }
    
    func fields(provider: TypeProvider) throws -> InputObjectConfigFieldMap {
        var map: InputObjectConfigFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(provider: provider)
            map[name] = field
        }
        
        return map
    }
    
    init(
        type: InputObjectType.Type,
        name: String?,
        fields: [InputFieldComponent<InputObjectType, InputObjectType.Keys, Context>]
    ) {
        self.fields = fields
        super.init(name: name  ?? Reflection.name(for: InputObjectType.self))
    }
}

public extension Input {
    convenience init(
        _ type: InputObjectType.Type,
        as name: String? = nil,
        _ fields: InputFieldComponent<InputObjectType, InputObjectType.Keys, Context>...
    ) {
        self.init(type: type, name: name, fields: fields)
    }
}
