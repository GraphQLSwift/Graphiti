import GraphQL
import OrderedCollections

open class Scalar<Resolver, Context, ScalarType : Codable> : Component<Resolver, Context> {
    override func update(typeProvider: SchemaTypeProvider) throws {
        let scalarType = try GraphQLScalarType(
            name: name,
            description: description,
            serialize: { value in
                guard let scalar = value as? ScalarType else {
                    throw GraphQLError(message: "Serialize expected type \(ScalarType.self) but got \(type(of: value))")
                }
                
                return try self.serialize(scalar: scalar)
            },
            parseValue: { map in
                let scalar = try self.parse(map: map)
                return try MapEncoder().encode(scalar)
            },
            parseLiteral: { value in
                let map = value.map
                let scalar = try self.parse(map: map)
                return try MapEncoder().encode(scalar)
            }
        )
        
        try typeProvider.map(ScalarType.self, to: scalarType)
    }
    
    open func serialize(scalar: ScalarType) throws -> Map {
        try MapEncoder().encode(scalar)
    }
    
    open func parse(map: Map) throws -> ScalarType {
        try MapDecoder().decode(ScalarType.self, from: map)
    }
    
    init(
        type: ScalarType.Type,
        name: String?
    ) {
        super.init(name: name ?? Reflection.name(for: ScalarType.self))
    }
}

public extension Scalar {
    convenience init(
        _ type: ScalarType.Type,
        as name: String? = nil
    )  {
        self.init(
            type: type,
            name: name
        )
    }
}

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
            let dictionary: OrderedDictionary<String, Map> = value.fields.reduce(into: [:]) { result, field in
                result[field.name.value] = field.value.map
            }
            
            return .dictionary(dictionary)
        }
        
        return .null
    }
}
