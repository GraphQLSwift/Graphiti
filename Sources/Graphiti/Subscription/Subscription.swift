import GraphQL

public final class Subscription<Resolver, Context>: Component<Resolver, Context> {
    let fields: [FieldComponent<Resolver, Context>]

    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        source is Resolver
    }

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        typeProvider.subscription = try GraphQLObjectType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider, coders: coders),
            isTypeOf: isTypeOf
        )
    }

    func fields(typeProvider: TypeProvider, coders: Coders) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]

        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider, coders: coders)
            map[name] = field
        }

        return map
    }

    init(
        name: String,
        fields: [FieldComponent<Resolver, Context>]
    ) {
        self.fields = fields
        super.init(
            name: name,
            type: .subscription
        )
    }
}

public extension Subscription {
    convenience init(
        as name: String = "Subscription",
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> FieldComponent<Resolver, Context>
    ) {
        self.init(name: name, fields: [fields()])
    }

    convenience init(
        as name: String = "Subscription",
        @FieldComponentBuilder<Resolver, Context> _ fields: ()
            -> [FieldComponent<Resolver, Context>]
    ) {
        self.init(name: name, fields: fields())
    }
}
