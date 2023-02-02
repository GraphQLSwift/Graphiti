import GraphQL

public final class Interface<Resolver, Context, InterfaceType>: TypeComponent<
    Resolver,
    Context
> {
    let fields: [FieldComponent<InterfaceType, Context>]

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let interfaceType = try GraphQLInterfaceType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider, coders: coders),
            resolveType: nil
        )

        try typeProvider.add(type: InterfaceType.self, as: interfaceType)
    }

    override func setGraphQLName(typeProvider: SchemaTypeProvider) throws {
        try typeProvider.mapName(InterfaceType.self, to: name)
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
        type _: InterfaceType.Type,
        name: String? = nil,
        fields: [FieldComponent<InterfaceType, Context>]
    ) {
        self.fields = fields
        super.init(name: name ?? Reflection.name(for: InterfaceType.self))
    }
}

public extension Interface {
    convenience init(
        _ type: InterfaceType.Type,
        as name: String? = nil,
        @FieldComponentBuilder<InterfaceType, Context> _ fields: ()
            -> FieldComponent<InterfaceType, Context>
    ) {
        self.init(
            type: type,
            name: name,
            fields: [fields()]
        )
    }

    convenience init(
        _ type: InterfaceType.Type,
        as name: String? = nil,
        @FieldComponentBuilder<InterfaceType, Context> _ fields: ()
            -> [FieldComponent<InterfaceType, Context>]
    ) {
        self.init(
            type: type,
            name: name,
            fields: fields()
        )
    }
}
