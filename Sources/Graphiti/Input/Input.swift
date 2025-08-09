import GraphQL

public final class Input<
    Resolver: Sendable,
    Context: Sendable,
    InputObjectType
>: TypeComponent<
    Resolver,
    Context
> {
    let isOneOf: Bool
    let fields: [InputFieldComponent<InputObjectType, Context>]

    override func update(typeProvider: SchemaTypeProvider, coders _: Coders) throws {
        let inputObjectType = try GraphQLInputObjectType(
            name: name,
            description: description,
            fields: {
                try self.fields(typeProvider: typeProvider)
            },
            isOneOf: isOneOf
        )

        try typeProvider.add(type: InputObjectType.self, as: inputObjectType)
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
        isOneOf: Bool,
        fields: [InputFieldComponent<InputObjectType, Context>]
    ) {
        self.isOneOf = isOneOf
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
        isOneOf: Bool = false,
        @InputFieldComponentBuilder<InputObjectType, Context> _ fields: ()
            -> InputFieldComponent<InputObjectType, Context>
    ) {
        self.init(type: type, name: name, isOneOf: isOneOf, fields: [fields()])
    }

    convenience init(
        _ type: InputObjectType.Type,
        as name: String? = nil,
        isOneOf: Bool = false,
        @InputFieldComponentBuilder<InputObjectType, Context> _ fields: ()
            -> [InputFieldComponent<InputObjectType, Context>]
    ) {
        self.init(type: type, name: name, isOneOf: isOneOf, fields: fields())
    }
}
