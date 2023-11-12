import GraphQL

public final class Input<
    Resolver,
    Context,
    InputObjectType
>: TypeComponent<
    Resolver,
    Context
> {
    let fields: [InputFieldComponent<InputObjectType, Context>]

    override func update(typeProvider: SchemaTypeProvider, coders _: Coders) throws {
        let inputObjectType = try GraphQLInputObjectType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider)
        )

        try typeProvider.add(type: InputObjectType.self, as: inputObjectType)
    }

    override func setGraphQLName(typeProvider: SchemaTypeProvider) throws {
        try typeProvider.mapName(InputObjectType.self, to: name)
    }

    func fields(typeProvider: TypeProvider) throws -> InputObjectFieldMap {
        var map: InputObjectFieldMap = [:]

        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider)
            map[name] = field
        }

        return map
    }

    init(
        type _: InputObjectType.Type,
        name: String?,
        fields: [InputFieldComponent<InputObjectType, Context>]
    ) {
        self.fields = fields
        super.init(
            name: name ?? Reflection.name(for: InputObjectType.self),
            type: .connection
        )
    }
}

public extension Input {
    convenience init(
        _ type: InputObjectType.Type,
        as name: String? = nil,
        @InputFieldComponentBuilder<InputObjectType, Context> _ fields: ()
            -> InputFieldComponent<InputObjectType, Context>
    ) {
        self.init(type: type, name: name, fields: [fields()])
    }

    convenience init(
        _ type: InputObjectType.Type,
        as name: String? = nil,
        @InputFieldComponentBuilder<InputObjectType, Context> _ fields: ()
            -> [InputFieldComponent<InputObjectType, Context>]
    ) {
        self.init(type: type, name: name, fields: fields())
    }
}
