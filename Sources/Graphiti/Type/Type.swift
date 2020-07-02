import GraphQL

public final class Type<RootType : Keyable, Context, ObjectType : Encodable & Keyable> : Component<RootType, Context> {
    let interfaces: [Any.Type]
    let fields: [FieldComponent<ObjectType, ObjectType.Keys, Context>]
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is ObjectType
    }
    
    override func update(builder: SchemaBuilder) throws {
        let objectType = try GraphQLObjectType(
            name: name,
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
        name: String?,
        interfaces: [Any.Type],
        fields: [FieldComponent<ObjectType, ObjectType.Keys, Context>]
    ) {
        self.interfaces = interfaces
        self.fields = fields
        super.init(name: name ?? Reflection.name(for: ObjectType.self))
    }
}

public extension Type {
    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        interfaces: [Any.Type] = [],
        _ fields: FieldComponent<ObjectType, ObjectType.Keys, Context>...
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: fields
        )
    }
}
