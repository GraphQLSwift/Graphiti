import GraphQL

public final class EnumTypeBuilder<Type : MapFallibleRepresentable> {
    public var description: String? = nil
    var values: GraphQLEnumValueMap = [:]

    public func value(
        name: String,
        value: Type,
        description: String? = nil,
        deprecationReason: String? = nil
    ) throws {
        let enumValue = GraphQLEnumValue(
            value: try value.asMap(),
            description: description,
            deprecationReason: deprecationReason
        )

        values[name] = enumValue
    }
}
