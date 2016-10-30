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

public struct EnumType<Type : MapFallibleRepresentable> {
    let enumType: GraphQLEnumType

    @discardableResult
    public init(name: String, build: (EnumTypeBuilder<Type>) throws -> Void) throws {
        let builder = EnumTypeBuilder<Type>()
        try build(builder)

        enumType = try GraphQLEnumType(
            name: name,
            description: builder.description,
            values: builder.values
        )
        
        link(Type.self, to: enumType)
    }
}
