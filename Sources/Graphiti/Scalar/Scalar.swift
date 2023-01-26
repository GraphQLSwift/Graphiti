import GraphQL
import OrderedCollections

/// Represents a scalar type in the schema.
///
/// It is **highly** recommended that you do not subclass this type.
/// Instead, modify the encoding/decoding behavior through the `MapEncoder`/`MapDecoder` options available through
/// `Coders` or a custom encoding/decoding on the `ScalarType` itself.
open class Scalar<Resolver, Context, ScalarType: Codable>: TypeComponent<Resolver, Context> {
    // TODO: Change this no longer be an open class

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let scalarType = try GraphQLScalarType(
            name: name,
            description: description,
            serialize: { value in
                guard let scalar = value as? ScalarType else {
                    throw GraphQLError(
                        message: "Serialize expected type \(ScalarType.self) but got \(type(of: value))"
                    )
                }

                return try self.serialize(scalar: scalar, encoder: coders.encoder)
            },
            parseValue: { map in
                let scalar = try self.parse(map: map, decoder: coders.decoder)
                return try self.serialize(scalar: scalar, encoder: coders.encoder)
            },
            parseLiteral: { value in
                let map = value.map
                let scalar = try self.parse(map: map, decoder: coders.decoder)
                return try self.serialize(scalar: scalar, encoder: coders.encoder)
            }
        )

        try typeProvider.map(ScalarType.self, to: scalarType)
        typeProvider.types.append(scalarType)
    }

    override func setGraphQLName(typeProvider: SchemaTypeProvider) throws {
        try typeProvider.mapName(ScalarType.self, to: name)
    }

    open func serialize(scalar: ScalarType, encoder: MapEncoder) throws -> Map {
        try encoder.encode(scalar)
    }

    open func parse(map: Map, decoder: MapDecoder) throws -> ScalarType {
        try decoder.decode(ScalarType.self, from: map)
    }

    init(
        type _: ScalarType.Type,
        name: String?
    ) {
        super.init(name: name ?? Reflection.name(for: ScalarType.self))
    }
}

public extension Scalar {
    convenience init(
        _ type: ScalarType.Type,
        as name: String? = nil
    ) {
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
            let value = self as? EnumValue
        {
            return .string(value.value)
        }

        if
            let value = self as? ListValue
        {
            let array = value.values.map { $0.map }
            return .array(array)
        }

        if
            let value = self as? ObjectValue
        {
            let dictionary: OrderedDictionary<String, Map> = value.fields
                .reduce(into: [:]) { result, field in
                    result[field.name.value] = field.value.map
                }

            return .dictionary(dictionary)
        }

        return .null
    }
}
