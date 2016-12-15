import GraphQL

public final class ObjectTypeBuilder<Root, Type> : FieldBuilder<Root, Type> {
    public var description: String? = nil
    var isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is Type
    }

    public func isTypeOf(_ f: @escaping GraphQLIsTypeOf) {
        self.isTypeOf = f
    }
}
