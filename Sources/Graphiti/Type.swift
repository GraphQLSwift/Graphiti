import GraphQL

public final class Type<RootType : Keyable, Context, ObjectType : Encodable & Keyable> : Component<RootType, Context> {
    let name: String?
    let interfaces: [Any.Type]
    let fields: [FieldComponent<ObjectType, ObjectType.Keys, Context>]
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is ObjectType
    }
    
    override func update(builder: SchemaBuilder) throws {
        let objectType = try GraphQLObjectType(
            name: name ?? Reflection.name(for: ObjectType.self),
            description: description,
            fields: fields(provider: builder),
            interfaces: interfaces.map {
                try builder.getInterfaceType(from: $0)
            },
            isTypeOf: isTypeOf
        )
        
        try builder.map(ObjectType.self, to: objectType)
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
        type: ObjectType.Type,
        name: String? = nil,
        interfaces: [Any.Type],
        fields: [FieldComponent<ObjectType, ObjectType.Keys, Context>]
    ) {
        self.name = name
        self.interfaces = interfaces
        self.fields = fields
    }
}
