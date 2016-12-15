import GraphQL

public typealias ResolveType<Type> = (
    _ value: Type,
    _ context: Any,
    _ info: GraphQLResolveInfo
) throws -> Any.Type

public final class InterfaceTypeBuilder<Root, Type> : FieldBuilder<Root, Type> {
    public var description: String? = nil
    var resolveType: GraphQLTypeResolve? = nil

    public func resolveType(_ resolve: @escaping ResolveType<Type>) {
        self.resolveType = { [weak self] value, context, info in
            guard let v = value as? Type else {
                throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: value))")
            }

            let type = try resolve(v, context, info)
            return try self?.schema.getObjectType(from: type) ?? "" // TODO: check this out
        }
    }
}
