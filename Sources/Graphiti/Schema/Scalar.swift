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

public final class Scalar<RootType : FieldKeyProvider, Context, ScalarType : Codable> : SchemaComponent<RootType, Context> {
    let name: String?
    let serialize: ((ScalarType) throws -> Map)?
    let parse: ((Map) throws -> ScalarType)?
    
    override func update(schema: SchemaThingy) {
        let scalarType = try! GraphQLScalarType(
            name: self.name ?? fixName(String(describing: ScalarType.self)),
            serialize: { value in
                guard let v = value as? ScalarType else {
                    throw GraphQLError(message: "Serialize expected type \(ScalarType.self) but got \(type(of: value))")
                }
                
                return try self.serialize?(v) ?? MapEncoder().encode(v)
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
        
        try! schema.map(ScalarType.self, to: scalarType)
    }
    
    public init(
        _ type: ScalarType.Type,
        name: String? = nil,
        serialize: ((ScalarType) throws -> Map)? = nil,
        parse: ((Map) throws -> ScalarType)? = nil
    ) {
        self.name = name
        self.serialize = serialize
        self.parse = parse
    }
}
