import GraphQL

public class ValueComponent<EnumType : Encodable & RawRepresentable> : Descriptable, Deprecatable where EnumType.RawValue == String {
    var description: String?
    var deprecationReason: String?
    
    func update(enum: EnumThingy) {}
    
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    public func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}

public class Value<EnumType : Encodable & RawRepresentable> : ValueComponent<EnumType> where EnumType.RawValue == String {
    let value: EnumType

    override func update(enum: EnumThingy) {
        let value = GraphQLEnumValue(
            value: try! MapEncoder().encode(self.value),
            description: self.description,
            deprecationReason: self.deprecationReason
        )
        
        `enum`.values[self.value.rawValue] = value
    }
    
    public init(_ value: EnumType) {
        self.value = value
    }
}

final class EnumThingy {
    var values: GraphQLEnumValueMap = [:]
}

private final class MergerValue<EnumType : Encodable & RawRepresentable> : ValueComponent<EnumType> where EnumType.RawValue == String {
    let components: [ValueComponent<EnumType>]
    
    init(components: [ValueComponent<EnumType>]) {
        self.components = components
    }
    
    override func update(enum: EnumThingy) {
        for component in components {
            component.update(enum: `enum`)
        }
    }
}

@_functionBuilder
public struct EnumTypeBuilder<EnumType : Encodable & RawRepresentable> where EnumType.RawValue == String {
    public static func buildBlock(_ components: ValueComponent<EnumType>...) -> ValueComponent<EnumType> {
        return MergerValue(components: components)
    }
}

public final class Enum<RootType : FieldKeyProvider, Context, EnumType : Encodable & RawRepresentable> : SchemaComponent<RootType, Context> where EnumType.RawValue == String {
    private let name: String?
    private let values: GraphQLEnumValueMap
    
    override func update(schema: SchemaThingy) {
        let enumType = try! GraphQLEnumType(
            name: self.name ?? fixName(String(describing: EnumType.self)),
            description: self.description,
            values: self.values
        )
        
        try! schema.map(EnumType.self, to: enumType)
    }
    
    public init(
        _ type: EnumType.Type,
        name: String? = nil,
        @EnumTypeBuilder<EnumType> component: () -> ValueComponent<EnumType>
    ) {
        self.name = name
        let component = component()
        let `enum` = EnumThingy()
        component.update(enum: `enum`)
        self.values = `enum`.values
    }
}

