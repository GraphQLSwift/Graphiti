import GraphQL

#warning("TODO: Rename to EnumValue")
public final class Value<EnumType>: EnumValueComponent<EnumType> where EnumType: Encodable & RawRepresentable, EnumType.RawValue == String {
    let value: EnumType
    var deprecationReason: String?
    
    override func enumValue(typeProvider: SchemaTypeProvider, coders: Coders) throws -> (String, GraphQLEnumValue) {
        let enumValue = GraphQLEnumValue(
            value: try MapEncoder().encode(value),
            description: description,
            deprecationReason: deprecationReason
        )
        
        return (value.rawValue, enumValue)
    }
    
    init(
        value: EnumType
    ) {
        self.value = value
        super.init()
    }
        
    public required init(stringLiteral string: StringLiteralType) {
        fatalError("init(stringLiteral:) has not been implemented")
    }
}

public extension Value {
    convenience init(_ value: EnumType) {
        self.init(value: value)
    }
    
    @available(*, deprecated, message: "Use a string literal above a component to give it a description.")
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    @available(*, deprecated, message: "Use deprecated(reason:).")
    func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
    
    func deprecated(reason deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
