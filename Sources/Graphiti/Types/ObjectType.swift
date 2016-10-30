import GraphQL

public final class ObjectTypeBuilder<Type> : FieldBuilder<Type> {
    public var description: String? = nil
    public var isTypeOf: GraphQLIsTypeOf? = nil

    public func isTypeOf(_ f: @escaping GraphQLIsTypeOf) {
        self.isTypeOf = f
    }
}

public struct ObjectType<Type> {
    let objectType: GraphQLObjectType

    @discardableResult
    public init(name: String, interfaces: Any.Type..., build: (ObjectTypeBuilder<Type>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Type>()
        try build(builder)
        
        objectType = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            interfaces: try interfaces.map({ try getInterface(from: $0) }),
            isTypeOf: builder.isTypeOf
        )

        link(Type.self, to: objectType)
    }
}
