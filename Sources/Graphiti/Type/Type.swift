import GraphQL

public final class Type<Resolver, Context, ObjectType: Encodable>: TypeComponent<
    Resolver,
    Context
> {
    let interfaces: [Any.Type]
    var keys: [KeyComponent<ObjectType, Resolver, Context>]
    let fields: [FieldComponent<ObjectType, Context>]

    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        source is ObjectType
    }

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let fieldDefs = try fields(typeProvider: typeProvider, coders: coders)
        let objectType = try GraphQLObjectType(
            name: name,
            description: description,
            fields: fieldDefs,
            interfaces: interfaces.map {
                try typeProvider.getInterfaceType(from: $0)
            },
            isTypeOf: isTypeOf
        )

        try typeProvider.add(type: ObjectType.self, as: objectType)

        // If federation keys are included, validate and create resolver closure
        if !keys.isEmpty {
            let fieldNames = Array(fieldDefs.keys)
            for key in keys {
                try key.validate(
                    againstFields: fieldNames,
                    typeProvider: typeProvider,
                    coders: coders
                )
            }

            let resolve: GraphQLFieldResolve = { source, args, context, eventLoopGroup, _ in
                guard let s = source as? Resolver else {
                    throw GraphQLError(
                        message: "Expected source type \(ObjectType.self) but got \(type(of: source))"
                    )
                }

                guard let c = context as? Context else {
                    throw GraphQLError(
                        message: "Expected context type \(Context.self) but got \(type(of: context))"
                    )
                }

                let keyMatch = self.keys.first { key in
                    key.mapMatchesArguments(args, coders: coders)
                }
                guard let key = keyMatch else {
                    throw GraphQLError(
                        message: "No matching key was found for representation \(args)."
                    )
                }

                return try key.resolveMap(
                    resolver: s,
                    context: c,
                    map: args,
                    eventLoopGroup: eventLoopGroup,
                    coders: coders
                )
            }

            typeProvider.federatedTypes.append(objectType)
            typeProvider.federatedResolvers[name] = resolve
        }
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
        keys: [KeyComponent<ObjectType, Resolver, Context>],
        fields: [FieldComponent<ObjectType, Context>]
    ) {
        self.interfaces = interfaces
        self.keys = keys
        self.fields = fields
        super.init(
            name: name ?? Reflection.name(for: ObjectType.self),
            type: .type
        )
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
            keys: [],
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
            keys: [],
            fields: fields()
        )
    }

    convenience init(
        resolver _: Resolver.Type,
        context _: Context.Type,
        _ type: ObjectType.Type,
        as name: String? = nil,
        interfaces: [Any.Type] = [],
        keys: [KeyComponent<ObjectType, Resolver, Context>] = [],
        fields: [FieldComponent<ObjectType, Context>]
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            keys: keys,
            fields: fields
        )
    }
}
