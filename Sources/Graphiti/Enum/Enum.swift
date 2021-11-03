import GraphQL

public final class Enum<Resolver, Context, EnumType>: Component<Resolver, Context> where EnumType: Encodable & RawRepresentable, EnumType.RawValue == String {
    private let enumValues: [EnumValueComponent<EnumType>]
    
    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let enumType = try GraphQLEnumType(
            name: name,
            description: description,
            values: enumValueMap(typeProvider: typeProvider, coders: coders)
        )
        
        try typeProvider.map(EnumType.self, to: enumType)
    }
    
    func enumValueMap(typeProvider: SchemaTypeProvider, coders: Coders) throws -> GraphQLEnumValueMap {
        var map: GraphQLEnumValueMap = [:]
        
        for enumValue in enumValues {
            let (name, enumValue) = try enumValue.enumValue(typeProvider: typeProvider, coders: coders)
            map[name] = enumValue
        }
        
        return map
    }
    
    private init(
        type: EnumType.Type,
        name: String?,
        values: [EnumValueComponent<EnumType>]
    ) {
        var description: String? = nil
        
        self.enumValues = values.reduce([]) { result, component in
            if let value = component as? Value {
                value.description = description
                description = nil
                return result + [value]
            } else if let componentDescription = component.description {
                description = (description ?? "") + componentDescription
            }
            
            return result
        }
        
        super.init(name: name ?? Reflection.name(for: EnumType.self))
    }

    public required init(stringLiteral string: StringLiteralType) {
        fatalError("init(stringLiteral:) has not been implemented")
    }
}

public extension Enum {
    convenience init(
        _ type: EnumType.Type,
        as name: String? = nil,
        @ValueBuilder<EnumType> _ values: () -> EnumValueComponent<EnumType>
    ) {
        self.init(type: type, name: name, values: [values()])
    }
    
    convenience init(
        _ type: EnumType.Type,
        as name: String? = nil,
        @ValueBuilder<EnumType> _ values: () -> [EnumValueComponent<EnumType>]
    ) {
        self.init(type: type, name: name, values: values())
    }
}
