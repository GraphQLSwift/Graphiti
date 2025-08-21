import GraphQL

public final class Type<
    Resolver: Sendable,
    Context: Sendable,
    ObjectType: Sendable
>: TypeComponent<
    Resolver,
    Context
> {
    let interfaces: [Any.Type]
    var keys: [KeyComponent<ObjectType, Resolver, Context>]
    let fields: [FieldComponent<ObjectType, Context>]

    let isTypeOf: GraphQLIsTypeOf = { source, _ in
        source is ObjectType
    }

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let objectType = try GraphQLObjectType(
            name: name,
            description: description,
            fields: {
                let fields = try self.fields(typeProvider: typeProvider, coders: coders)
                // Validate federation keys, if present
                for key in self.keys {
                    try key.validate(againstFields: Array(fields.keys))
                }
                return fields
            },
            interfaces: {
                try self.interfaces.map {
                    try typeProvider.getInterfaceType(from: $0)
                }
            },
            isTypeOf: isTypeOf
        )

        try typeProvider.add(type: ObjectType.self, as: objectType)

        // If federation keys are included, create resolver closure
        if !keys.isEmpty {
            let keys = self.keys
            let resolve: GraphQLFieldResolve = { source, args, context, _ in
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

                let keyMatch = keys.first { key in
                    key.mapMatchesArguments(args, coders: coders)
                }
                guard let key = keyMatch else {
                    throw GraphQLError(
                        message: "No matching key was found for representation \(args)."
                    )
                }

                return try await key.resolveMap(
                    resolver: s,
                    context: c,
                    map: args,
                    coders: coders
                )
            }

            typeProvider.federatedTypes.append(objectType)
            typeProvider.federatedResolvers[name] = resolve
        }
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
