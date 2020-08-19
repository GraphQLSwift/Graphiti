import GraphQL

public final class Enum<Resolver, Context, EnumType : Encodable & RawRepresentable> : Component<Resolver, Context> where EnumType.RawValue == String {
    private let values: [Value<EnumType>]
    
    override func update(typeProvider: SchemaTypeProvider) throws {
        let enumType = try GraphQLEnumType(
            name: name,
            description: description,
            values: values.reduce(into: [:]) { result, value in
                result[value.value.rawValue] = GraphQLEnumValue(
                    value: try MapEncoder().encode(value.value),
                    description: value.description,
                    deprecationReason: value.deprecationReason
                )
            }
        )
        
        try typeProvider.map(EnumType.self, to: enumType)
    }
    
    private init(
        type: EnumType.Type,
        name: String?,
        values: [Value<EnumType>]
    ) {
        self.values = values
        super.init(name: name ?? Reflection.name(for: EnumType.self))
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
