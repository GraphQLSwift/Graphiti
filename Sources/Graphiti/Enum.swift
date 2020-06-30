import GraphQL

public final class Enum<RootType : Keyable, Context, EnumType : Enumerable> : Component<RootType, Context> {
    private let values: [Value<EnumType>]
    
    override func update(builder: SchemaBuilder) throws {
        let enumType = try GraphQLEnumType(
            name: name,
            description: description,
            values: values.reduce(into: [:]) { result, value in
                result[value.value.rawValue] = GraphQLEnumValue(
                    value: try MapEncoder().encode( value.value),
                    description: value.description,
                    deprecationReason: value.deprecationReason
                )
            }
        )
        
        try builder.map(EnumType.self, to: enumType)
    }
    
    init(
        type: EnumType.Type,
        name: String?,
        values: [Value<EnumType>]
    ) {
        self.values = values
        super.init(name: name ?? Reflection.name(for: EnumType.self))
    }
}
