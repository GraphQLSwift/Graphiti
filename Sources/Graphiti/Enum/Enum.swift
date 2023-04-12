import GraphQL

public final class Enum<
    Resolver,
    Context,
    EnumType: Encodable & RawRepresentable
>: TypeComponent<
    Resolver,
    Context
> where EnumType.RawValue == String {
    private let values: [Value<EnumType>]

    override func update(typeProvider: SchemaTypeProvider, coders _: Coders) throws {
        let enumType = try GraphQLEnumType(
            name: name,
            description: description,
            values: values.reduce(into: [:]) { result, value in
                result[value.value.rawValue] = try GraphQLEnumValue(
                    value: MapEncoder().encode(value.value),
                    description: value.description,
                    deprecationReason: value.deprecationReason
                )
            }
        )

        try typeProvider.add(type: EnumType.self, as: enumType)
    }

    override func setGraphQLName(typeProvider: SchemaTypeProvider) throws {
        try typeProvider.mapName(EnumType.self, to: name)
    }

    private init(
        type _: EnumType.Type,
        name: String?,
        values: [Value<EnumType>]
    ) {
        self.values = values
        super.init(
            name: name ?? Reflection.name(for: EnumType.self),
            type: .enum
        )
    }
}

public extension Enum {
    convenience init(
        _ type: EnumType.Type,
        as name: String? = nil,
        @ValueBuilder<EnumType> _ values: () -> Value<EnumType>
    ) {
        self.init(type: type, name: name, values: [values()])
    }

    convenience init(
        _ type: EnumType.Type,
        as name: String? = nil,
        @ValueBuilder<EnumType> _ values: () -> [Value<EnumType>]
    ) {
        self.init(type: type, name: name, values: values())
    }
}
