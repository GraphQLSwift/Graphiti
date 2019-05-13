import GraphQL
import Runtime
import NIO

public final class SchemaBuilder<Root, Context, EventLoop: EventLoopGroup> {
    var graphQLTypeMap: [AnyType: GraphQLType] = [
        AnyType(Int.self): GraphQLInt,
        AnyType(Double.self): GraphQLFloat,
        AnyType(String.self): GraphQLString,
        AnyType(Bool.self): GraphQLBoolean,
        ]

    var query: GraphQLObjectType? = nil
    var mutation: GraphQLObjectType? = nil
    var subscription: GraphQLObjectType? = nil
    public var types: [Any.Type] = []
    // TODO: Add support for directives
    var directives: [GraphQLDirective] = []

    init() {}

    public func query(name: String = "Query", build: (ObjectTypeBuilder<Root, Context, EventLoop, Root>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Root, Context, EventLoop, Root>(schema: self)
        try build(builder)

        query = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            isTypeOf: builder.isTypeOf
        )
    }

    public func mutation(name: String = "Mutation", build: (ObjectTypeBuilder<Root, Context, EventLoop, Root>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Root, Context, EventLoop, Root>(schema: self)
        try build(builder)

        mutation = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            isTypeOf: builder.isTypeOf
        )
    }

    public func subscription(name: String = "Subscription", build: (ObjectTypeBuilder<Root, Context, EventLoop, Root>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Root, Context, EventLoop, Root>(schema: self)
        try build(builder)

        subscription = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            isTypeOf: builder.isTypeOf
        )
    }

    public func object<Type>(
        type: Type.Type,
        interfaces: Any.Type...,
        build: (ObjectTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        let name = fixName(String(describing: Type.self))
        try `object`(name: name, type: type, interfaces: interfaces, build: build)
    }

    public func object<Type>(
        type: Type.Type,
        name: String,
        interfaces: Any.Type...,
        build: (ObjectTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        try `object`(name: name, type: type, interfaces: interfaces, build: build)
    }

    private func `object`<Type>(
        name: String,
        type: Type.Type,
        interfaces: [Any.Type],
        build: (ObjectTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        let builder = ObjectTypeBuilder<Root, Context, EventLoop, Type>(schema: self)
        try build(builder)

        let objectType = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            interfaces: try interfaces.map({ try getInterfaceType(from: $0) }),
            isTypeOf: builder.isTypeOf
        )

        try map(Type.self, to: objectType)
    }

    public func inputObject<Type: InputType>(
        type: Type.Type,
        build: (InputObjectTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        let name = fixName(String(describing: Type.self))
        try inputObject(name: name, type: type, build: build)
    }

    public func inputObject<Type: InputType>(
        name: String,
        type: Type.Type,
        build: (InputObjectTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        let builder = InputObjectTypeBuilder<Root, Context, EventLoop, Type>(schema: self)
        try build(builder)

        let inputObjectType = try GraphQLInputObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields
        )

        try map(Type.self, to: inputObjectType)
    }

    public func interface<Type>(
        type: Type.Type,
        build: (InterfaceTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        let name = fixName(String(describing: Type.self))
        try interface(name: name, type: type, build: build)
    }

    public func interface<Type>(
        name: String,
        type: Type.Type,
        build: (InterfaceTypeBuilder<Root, Context, EventLoop, Type>) throws -> Void
        ) throws {
        let builder = InterfaceTypeBuilder<Root, Context, EventLoop, Type>(schema: self)
        try build(builder)

        let interfaceType = try GraphQLInterfaceType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            resolveType: builder.resolveType
        )

        try map(Type.self, to: interfaceType)
    }

    public func union<Type>(
        type: Type.Type,
        members: [Any.Type]
        ) throws {
        let name = fixName(String(describing: Type.self))
        try union(name: name, type: type, members: members)
    }

    public func union<Type>(
        name: String,
        type: Type.Type,
        members: [Any.Type]
        ) throws {
        try union(name: name, type: type) { builder in
            builder.types = members
        }
    }

    public func union<Type>(
        type: Type.Type,
        build: (UnionTypeBuilder<Type>) throws -> Void
        ) throws {
        let name = fixName(String(describing: Type.self))
        try union(name: name, type: type, build: build)
    }

    public func union<Type>(
        name: String,
        type: Type.Type,
        build: (UnionTypeBuilder<Type>) throws -> Void
        ) throws {
        let builder = UnionTypeBuilder<Type>()
        try build(builder)

        let interfaceType = try GraphQLUnionType(
            name: name,
            description: builder.description,
            resolveType: builder.resolveType,
            types: builder.types.map { try getObjectType(from: $0) }
        )

        try map(Type.self, to: interfaceType)
    }

    public func `enum`<Type : OutputType>(
        type: Type.Type,
        build: (EnumTypeBuilder<Type>) throws -> Void
        ) throws {
        let name = fixName(String(describing: Type.self))
        try `enum`(name: name, type: type, build: build)
    }

    public func `enum`<Type : OutputType>(
        name: String,
        type: Type.Type,
        build: (EnumTypeBuilder<Type>) throws -> Void
        ) throws {
        let builder = EnumTypeBuilder<Type>()
        try build(builder)

        let enumType = try GraphQLEnumType(
            name: name,
            description: builder.description,
            values: builder.values
        )

        try map(Type.self, to: enumType)
    }

    public func scalar<Type : OutputType>(
        type: Type.Type,
        build: (ScalarTypeBuilder<Type>) throws -> Void
        ) throws {
        let name = fixName(String(describing: Type.self))
        try scalar(name: name, type: type, build: build)
    }

    public func scalar<Type : OutputType>(
        name: String,
        type: Type.Type,
        build: (ScalarTypeBuilder<Type>) throws -> Void
        ) throws {
        let builder = ScalarTypeBuilder<Type>()
        try build(builder)

        if builder.parseValue != nil && builder.parseLiteral == nil {
            throw GraphQLError(
                message: "parseLiteral function is required."
            )
        }

        if builder.parseValue == nil && builder.parseLiteral != nil {
            throw GraphQLError(
                message: "parseValue function is required."
            )
        }

        let scalarType: GraphQLScalarType

        if let parseValue = builder.parseValue, let parseLiteral = builder.parseLiteral {
            scalarType = try GraphQLScalarType(
                name: name,
                description: builder.description,
                serialize: builder.serialize,
                parseValue: parseValue,
                parseLiteral: parseLiteral
            )
        } else {
            scalarType = try GraphQLScalarType(
                name: name,
                description: builder.description,
                serialize: builder.serialize
            )
        }

        try map(Type.self, to: scalarType)
    }
}

public extension SchemaBuilder {
    func map(_ type: Any.Type, to graphQLType: GraphQLType) throws {
        guard !(type is Void.Type) else {
            return
        }

        let key = AnyType(type)
        guard graphQLTypeMap[key] == nil else {
            throw GraphQLError(
                message: "Duplicate type registration: \(graphQLType.debugDescription)"
            )
        }

        graphQLTypeMap[key] = graphQLType
    }

    func getTypes() throws -> [GraphQLNamedType] {
        return try types.map({ try getNamedType(from: $0) })
    }

    static private func getGraphQLOptionalType(from type: GraphQLType, isOptional: Bool) -> GraphQLType? {
        if isOptional {
            return type
        } else if let type = type as? GraphQLNullableType {
            return GraphQLNonNull(type)
        } else {
            // TODO: Throw error
            return nil
        }
    }

    func getGraphQLType(from type: Any.Type, isOptional: Bool = false) -> GraphQLType? {
        if let type = type as? Wrapper.Type {
            switch type.modifier {
            case .optional:
                return getGraphQLType(from: type.wrappedType, isOptional: true)
            case .list:
                return getGraphQLType(from: type.wrappedType).flatMap {
                    SchemaBuilder.getGraphQLOptionalType(from: GraphQLList($0), isOptional: isOptional)
                }
            case .reference:
                let name = fixName(String(describing: type.wrappedType))
                let referenceType = GraphQLTypeReference(name)

                return SchemaBuilder.getGraphQLOptionalType(from: referenceType, isOptional: isOptional)
            }
        } else {
            return graphQLTypeMap[AnyType(type)].flatMap {
                SchemaBuilder.getGraphQLOptionalType(from: $0, isOptional: isOptional)
            }
        }
    }

    func getOutputType(from type: Any.Type, field: String) throws -> GraphQLOutputType {
        // TODO: Remove this when Reflection error is fixed
        guard isMapFallibleRepresentable(type: type) else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not conform to \"MapFallibleRepresentable\"."
            )
        }

        guard let graphQLType = getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not map to a GraphQL type."
            )
        }

        guard let outputType = graphQLType as? GraphQLOutputType else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Mapped GraphQL type is not an output type."
            )
        }

        return outputType
    }

    func getInputType(from type: Any.Type, field: String) throws -> GraphQLInputType {
        guard let graphQLType = getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not map to a GraphQL type."
            )
        }

        guard let inputType = graphQLType as? GraphQLInputType else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Mapped GraphQL type is not an input type."
            )
        }

        return inputType
    }

    func getNamedType(from type: Any.Type) throws -> GraphQLNamedType {
        guard let graphQLType = getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                "Cannot use type \"\(type)\" as named type. " +
                "Type does not map to a GraphQL type."
            )
        }

        guard let namedType = GraphQL.getNamedType(type: graphQLType) else {
            throw GraphQLError(
                message:
                "Cannot use type \"\(type)\" as named type. " +
                "Mapped GraphQL type is not a named type."
            )
        }

        return namedType
    }

    func getInterfaceType(from type: Any.Type) throws -> GraphQLInterfaceType {
        // TODO: Remove this when Reflection error is fixed
        guard isProtocol(type: type) else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Type is not a protocol."
            )
        }

        guard let graphQLType = getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Type does not map to a GraphQL type."
            )
        }

        guard let nonNull = graphQLType as? GraphQLNonNull else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Mapped GraphQL type is nullable."
            )
        }

        guard let interfaceType = nonNull.ofType as? GraphQLInterfaceType else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Mapped GraphQL type is not an interface type."
            )
        }

        return interfaceType
    }

    func getObjectType(from type: Any.Type) throws -> GraphQLObjectType {
        guard let graphQLType = getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Type does not map to a GraphQL type."
            )
        }

        guard let nonNull = graphQLType as? GraphQLNonNull else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Mapped GraphQL type is nullable."
            )
        }

        guard let objectType = nonNull.ofType as? GraphQLObjectType else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Mapped GraphQL type is not an object type."
            )
        }

        return objectType
    }
}

extension SchemaBuilder {
    func arguments(type: Any.Type, field: String) throws -> [String: GraphQLArgument] {
        var arguments: [String: GraphQLArgument] = [:]

        guard let argumentsType = type as? Arguments.Type else {
            return [:]
        }

        let info = try typeInfo(of: type)
        for property in info.properties {
            if case let propertyType as MapInitializable.Type = property.type {
                let argument =  GraphQLArgument(
                    type: try getInputType(from: propertyType, field: field),
                    description: argumentsType.descriptions[property.name],
                    defaultValue: try argumentsType.defaultValues[property.name]?.asMap()
                )

                arguments[property.name] = argument
            }
        }

        return arguments
    }
}

public typealias NoRoot = Void
public typealias NoContext = Void

public struct Schema<Root, Context, EventLoop: EventLoopGroup> {
    public let schema: GraphQLSchema

    public init(_ build: (SchemaBuilder<Root, Context, EventLoop>) throws -> Void) throws {
        let builder = SchemaBuilder<Root, Context, EventLoop>()
        try build(builder)

        guard let query = builder.query else {
            throw GraphQLError(
                message: "Query type is required."
            )
        }

        schema = try GraphQLSchema(
            query: query,
            mutation: builder.mutation,
            subscription: builder.subscription,
            types: builder.getTypes(),
            directives: builder.directives
        )
    }

    public func execute(
        request: String,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
        ) throws -> EventLoopFuture<Map> {
        guard Root.self is Void.Type else {
            throw GraphQLError(
                message: "Root value is required."
            )
        }

        return try graphql(
            schema: schema,
            request: request,
            eventLoopGroup: eventLoopGroup,
            variableValues: variables,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        rootValue: Root,
        worker: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
        ) throws -> EventLoopFuture<Map> {
        return try graphql(
            schema: schema,
            request: request,
            rootValue: rootValue,
            eventLoopGroup: worker,
            variableValues: variables,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        context: Context,
        eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
        ) throws -> EventLoopFuture<Map> {
        guard Root.self is Void.Type else {
            throw GraphQLError(
                message: "Root value is required."
            )
        }

        return try graphql(
            schema: schema,
            request: request,
            context: context,
            eventLoopGroup: eventLoopGroup,
            variableValues: variables,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        rootValue: Root,
        context: Context,
        worker: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
        ) throws -> EventLoopFuture<Map> {
        return try graphql(
            schema: schema,
            request: request,
            rootValue: rootValue,
            context: context,
            eventLoopGroup: worker,
            variableValues: variables,
            operationName: operationName
        )
    }
}
