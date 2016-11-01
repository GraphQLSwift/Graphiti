import GraphQL

public final class ObjectTypeBuilder<Type> : FieldBuilder<Type> {
    public var description: String? = nil
    var isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is Type
    }

    public func isTypeOf(_ f: @escaping GraphQLIsTypeOf) {
        self.isTypeOf = f
    }
}

public struct ObjectType<Type> {
    let objectType: GraphQLObjectType

    @discardableResult
    public init(name: String, interfaces: Any.Type..., build: (ObjectTypeBuilder<Type>) throws -> Void) throws {
        try self.init(name: name, interfaceTypes: interfaces, build: build)
    }

    @discardableResult
    public init(interfaces: Any.Type..., build: (ObjectTypeBuilder<Type>) throws -> Void) throws {
        let name = fixName(String(describing: Type.self))
        try self.init(name: name, interfaceTypes: interfaces, build: build)
    }

    @discardableResult
    private init(name: String, interfaceTypes: [Any.Type], build: (ObjectTypeBuilder<Type>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Type>()
        try build(builder)
        
        objectType = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            interfaces: try interfaceTypes.map({ try getInterfaceType(from: $0) }),
            isTypeOf: builder.isTypeOf
        )

        link(Type.self, to: objectType)
    }
}
