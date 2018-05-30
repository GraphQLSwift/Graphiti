import GraphQL
import NIO

public typealias IsTypeOf<S, C> = (
    _ source: S,
    _ context: C,
    _ info: GraphQLResolveInfo
) throws -> Bool

public final class ObjectTypeBuilder<Root, Context: EventLoopGroup, Type> : FieldBuilder<Root, Context, Type> {
    public var description: String? = nil

    var isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is Type
    }

    public func isTypeOf(_ f: @escaping IsTypeOf<Type, Context>) {
        self.isTypeOf = { source, context, info in
            guard let s = source as? Type else {
                throw GraphQLError(message: "Expected source type \(Type.self) but got \(type(of: source))")
            }

            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
            }

            return try f(s, c, info)
        }
    }
}
