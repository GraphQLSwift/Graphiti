import GraphQL

public typealias ResolveType<Value, Context> = (
    _ value: Value,
    _ context: Context,
    _ info: GraphQLResolveInfo
) throws -> Any.Type

public final class InterfaceTypeBuilder<Root, Context, Type> : FieldBuilder<Root, Context, Type> {
    public var description: String? = nil
    var resolveType: GraphQLTypeResolve? = nil

    public func resolveType(_ resolve: @escaping ResolveType<Type, Context>) {
        self.resolveType = { value, context, info in
            guard let v = value as? Type else {
                throw GraphQLError(message: "Expected value type \(Type.self) but got \(Swift.type(of: value))")
            }

            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
            }

            let type = try resolve(v, c, info)
            return try self.schema.getObjectType(from: type)
        }
    }
}
