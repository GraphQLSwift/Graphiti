import GraphQL
import OrderedCollections

/// Represents a scalar type in the schema.
///
/// It is **highly** recommended that you do not subclass this type.
/// Encoding/decoding behavior can be modified through the `MapEncoder`/`MapDecoder` options available through
/// `Coders` or a custom encoding/decoding on the `ScalarType` itself. If you need very custom serialization controls,
/// you may provide your own serialize, parseValue, and parseLiteral implementations.
open class Scalar<
    Resolver: Sendable,
    Context: Sendable,
    ScalarType: Codable
>: TypeComponent<Resolver, Context> {
    // TODO: Change this no longer be an open class
    let specifiedByURL: String?

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        let serialize = self.serialize
        let parseValue = self.parseValue
        let parseLiteral = self.parseLiteral

        let scalarType = try GraphQLScalarType(
            name: name,
            description: description,
            specifiedByURL: specifiedByURL,
            serialize: { value in
                try serialize(value, coders)
            },
            parseValue: { map in
                try parseValue(map, coders)
            },
            parseLiteral: { value in
                try parseLiteral(value, coders)
            }
        )

        try typeProvider.add(type: ScalarType.self, as: scalarType)
    }

    // TODO: Remove open func, instead relying on a passed closure
    open func serialize(scalar: ScalarType, encoder: MapEncoder) throws -> Map {
        try encoder.encode(scalar)
    }

    // TODO: Remove open func, instead relying on a passed closure
    open func parse(map: Map, decoder: MapDecoder) throws -> ScalarType {
        try decoder.decode(ScalarType.self, from: map)
    }

    let serialize: @Sendable (Any, Coders) throws -> Map
    let parseValue: @Sendable (Map, Coders) throws -> Map
    let parseLiteral: @Sendable (GraphQL.Value, Coders) throws -> Map

    init(
        type _: ScalarType.Type,
        name: String?,
        specifiedBy: String? = nil,
        serialize: (@Sendable (Any, Coders) throws -> Map)? = nil,
        parseValue: (@Sendable (Map, Coders) throws -> Map)? = nil,
        parseLiteral: (@Sendable (GraphQL.Value, Coders) throws -> Map)? = nil
    ) {
        specifiedByURL = specifiedBy
        self.serialize = serialize ?? Self.defaultSerialize
        self.parseValue = parseValue ?? Self.defaultParseValue
        self.parseLiteral = parseLiteral ?? Self.defaultParseLiteral
        super.init(
            name: name ?? Reflection.name(for: ScalarType.self),
            type: .scalar
        )
    }

    @Sendable
    private static func defaultSerialize(value: Any, coders: Coders) throws -> Map {
        guard let scalar = value as? ScalarType else {
            throw GraphQLError(
                message: "Serialize expected type \(ScalarType.self) but got \(type(of: value))"
            )
        }
        return try coders.encoder.encode(scalar)
    }

    @Sendable
    private static func defaultParseValue(map: Map, coders: Coders) throws -> Map {
        let scalar = try coders.decoder.decode(ScalarType.self, from: map)
        return try coders.encoder.encode(scalar)
    }

    @Sendable
    private static func defaultParseLiteral(value: GraphQL.Value, coders: Coders) throws -> Map {
        let map = value.map
        let scalar = try coders.decoder.decode(ScalarType.self, from: map)
        return try coders.encoder.encode(scalar)
    }
}

public extension Scalar {
    convenience init(
        _ type: ScalarType.Type,
        as name: String? = nil,
        specifiedBy: String? = nil,
        serialize: (@Sendable (Any, Coders) throws -> Map)? = nil,
        parseValue: (@Sendable (Map, Coders) throws -> Map)? = nil,
        parseLiteral: (@Sendable (GraphQL.Value, Coders) throws -> Map)? = nil
    ) {
        self.init(
            type: type,
            name: name,
            specifiedBy: specifiedBy,
            serialize: serialize,
            parseValue: parseValue,
            parseLiteral: parseLiteral
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
