import GraphQL

public final class ScalarTypeBuilder<Type : MapFallibleRepresentable> {
    public var description: String? = nil

    var serialize: (Any) throws -> Map = { value in
        guard let v = value as? Type else {
            throw GraphQLError(message: "Serialize expected type \(Type.self) but got \(type(of: value))")
        }

        return try v.asMap()
    }

    var parseValue: ((Map) throws -> Map)? = nil
    var parseLiteral: ((Value) throws -> Map)? = nil

    public func serialize(serialize: @escaping (Type) throws -> Map) {
        self.serialize = { value in
            guard let v = value as? Type else {
                throw GraphQLError(message: "Serialize expected type \(Type.self) but got \(type(of: value))")
            }

            return try serialize(v)
        }
    }

    public func parseValue(parseValue: @escaping (Map) throws -> Map) {
        self.parseValue = parseValue
    }

    public func parseLiteral(parseLiteral: @escaping (Value) throws -> Map) {
        self.parseLiteral = parseLiteral
    }
}
