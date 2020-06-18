import GraphQL

extension GraphQL.Value {
    var map: Map {
        if
            let value = self as? BooleanValue
        {
            return .bool(value.value)
        }
        
        if
            let value = self as? IntValue,
            let int = Int(value.value)
        {
            return .int(int)
        }
        
        if
            let value = self as? FloatValue,
            let double = Double(value.value)
        {
            return .double(double)
        }
        
        if
            let value = self as? StringValue
        {
            return .string(value.value)
        }
        
        if
            let value = self as? ListValue
        {
            let array = value.values.map({ $0.map })
            return .array(array)
        }
        
        if
            let value = self as? ObjectValue
        {
            let dictionary = value.fields.reduce(into: [:]) { result, field in
                result[field.name.value] = field.value.map
            }
            
            return .dictionary(dictionary)
        }
        
        return .null
    }
}

public final class Scalar<RootType : Keyable, Context, ScalarType : Codable> : Component<RootType, Context> {
    let name: String?
    let serialize: ((ScalarType) throws -> Map)?
    let parse: ((Map) throws -> ScalarType)?
    
    override func update(builder: SchemaBuilder) throws {
        let scalarType = try GraphQLScalarType(
            name: name ?? Reflection.name(for: ScalarType.self),
            serialize: { value in
                guard let scalarValue = value as? ScalarType else {
                    throw GraphQLError(message: "Serialize expected type \(ScalarType.self) but got \(type(of: value))")
                }
                
                return try self.serialize?(scalarValue) ?? MapEncoder().encode(scalarValue)
            },
            parseValue: { map in
                let scalar = try MapDecoder().decode(ScalarType.self, from: map)
                return try MapEncoder().encode(scalar)
            },
            parseLiteral: { value in
                let scalar = try MapDecoder().decode(ScalarType.self, from: value.map)
                return try MapEncoder().encode(scalar)
            }
        )
        
        try builder.map(ScalarType.self, to: scalarType)
    }
    
    init(
        type: ScalarType.Type,
        name: String?,
        serialize: ((ScalarType) throws -> Map)?,
        parse: ((Map) throws -> ScalarType)?
    ) {
        self.name = name
        self.serialize = serialize
        self.parse = parse
    }
}
