import GraphQL

public final class Type<Resolver, Context, ObjectType: Encodable>: Component<Resolver, Context> {
    let interfaces: [Any.Type]
    let fields: [FieldComponent<ObjectType, Context>]

    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        source is ObjectType
    }

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let objectType = try GraphQLObjectType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider, coders: coders),
            interfaces: interfaces.map {
                try typeProvider.getInterfaceType(from: $0)
            },
            isTypeOf: isTypeOf
        )

        try typeProvider.map(ObjectType.self, to: objectType)
        typeProvider.types.append(objectType)
    }

    override func setGraphQLName(typeProvider: SchemaTypeProvider) throws {
        try typeProvider.mapName(ObjectType.self, to: name)
    }

    func fields(typeProvider: TypeProvider, coders: Coders) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]

        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider, coders: coders)
            map[name] = field
        }

        return map
    }

    private init(
        type _: ObjectType.Type,
        name: String?,
        interfaces: [Any.Type],
        fields: [FieldComponent<ObjectType, Context>]
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
        @FieldComponentBuilder<ObjectType, Context> _ fields: ()
            -> FieldComponent<ObjectType, Context>
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: [fields()]
        )
    }

    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        interfaces: [Any.Type] = [],
        @FieldComponentBuilder<ObjectType, Context> _ fields: ()
            -> [FieldComponent<ObjectType, Context>]
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: fields()
        )
    }
}
