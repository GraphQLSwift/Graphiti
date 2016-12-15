import GraphQL

public final class SchemaBuilder<Root, Context> {
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

    public func query(name: String = "Query", build: (ObjectTypeBuilder<Root, Context, Root>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Root, Context, Root>(schema: self)
        try build(builder)

        query = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            isTypeOf: builder.isTypeOf
        )
    }

    public func mutation(name: String = "Mutation", build: (ObjectTypeBuilder<Root, Context, Root>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Root, Context, Root>(schema: self)
        try build(builder)

        mutation = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            isTypeOf: builder.isTypeOf
        )
    }

    public func subscription(name: String = "Subscription", build: (ObjectTypeBuilder<Root, Context, Root>) throws -> Void) throws {
        let builder = ObjectTypeBuilder<Root, Context, Root>(schema: self)
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
        build: (ObjectTypeBuilder<Root, Context, Type>) throws -> Void
    ) throws {
        let name = fixName(String(describing: Type.self))
        try `object`(name: name, type: type, interfaces: interfaces, build: build)
    }

    public func object<Type>(
        type: Type.Type,
        name: String,
        interfaces: Any.Type...,
        build: (ObjectTypeBuilder<Root, Context, Type>) throws -> Void
    ) throws {
        try `object`(name: name, type: type, interfaces: interfaces, build: build)
    }

    private func `object`<Type>(
        name: String,
        type: Type.Type,
        interfaces: [Any.Type],
        build: (ObjectTypeBuilder<Root, Context, Type>) throws -> Void
    ) throws {
        let builder = ObjectTypeBuilder<Root, Context, Type>(schema: self)
        try builder.addAllFields()
        try build(builder)

        let objectType = try GraphQLObjectType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            interfaces: try interfaces.map({ try getInterfaceType(from: $0) }),
            isTypeOf: builder.isTypeOf
        )

        map(Type.self, to: objectType)
    }

    public func interface<Type>(
        type: Type.Type,
        build: (InterfaceTypeBuilder<Root, Context, Type>) throws -> Void
    ) throws {
        let name = fixName(String(describing: Type.self))
        try interface(name: name, type: type, build: build)
    }

    public func interface<Type>(
        name: String,
        type: Type.Type,
        build: (InterfaceTypeBuilder<Root, Context, Type>) throws -> Void
    ) throws {
        let builder = InterfaceTypeBuilder<Root, Context, Type>(schema: self)
        try build(builder)

        let interfaceType = try GraphQLInterfaceType(
            name: name,
            description: builder.description,
            fields: builder.fields,
            resolveType: builder.resolveType
        )

        map(Type.self, to: interfaceType)
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

        map(Type.self, to: enumType)
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

        map(Type.self, to: scalarType)
    }
}

extension SchemaBuilder {
    func map(_ type: Any.Type, to graphQLType: GraphQLType) {
        guard !(type is Void.Type) else {
            return
        }

        graphQLTypeMap[AnyType(type)] = graphQLType
    }

    func getTypes() throws -> [GraphQLNamedType] {
        return try types.map({ try getNamedType(from: $0) })
    }

    func getGraphQLType(from type: Any.Type) -> GraphQLType? {
        if let type = type as? Wrapper.Type {
            switch type.modifier {
            case .optional:
                if let wrapper = type.wrappedType as? Wrapper.Type {
                    if case .reference = wrapper.modifier {
                        let name = fixName(String(describing: wrapper.wrappedType))
                        return GraphQLTypeReference(name)
                    } else {
                        return getGraphQLType(from: type.wrappedType)
                    }
                } else {
                    return graphQLTypeMap[AnyType(type.wrappedType)]
                }
            case .list:
                if type.wrappedType is Wrapper.Type {
                    let unwrapped = getGraphQLType(from: type.wrappedType)
                    return unwrapped.map { GraphQLList($0) }
                } else {
                    let unwrapped = graphQLTypeMap[AnyType(type.wrappedType)]
                    // TODO: check if it's nullable and throw error
                    return unwrapped.map { GraphQLList(GraphQLNonNull($0 as! GraphQLNullableType)) }
                }
            case .reference:
                let name = fixName(String(describing: type.wrappedType))
                return GraphQLNonNull(GraphQLTypeReference(name))
            }
        }

        return graphQLTypeMap[AnyType(type)].flatMap {
            guard let nullable = $0 as? GraphQLNullableType else {
                return nil
            }
            
            return GraphQLNonNull(nullable)
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

        for property in try properties(type) {
            if case let propertyType as MapInitializable.Type = property.type {
                let argument =  GraphQLArgument(
                    type: try getInputType(from: propertyType, field: field),
                    description: argumentsType.descriptions[property.key],
                    defaultValue: try argumentsType.defaultValues[property.key]?.asMap()
                )

                arguments[property.key] = argument
            }
        }
        
        return arguments
    }
}

public typealias NoRoot = Void
public typealias NoContext = Void

public struct Schema<Root, Context> {
    let schema: GraphQLSchema

    public init(_ build: (SchemaBuilder<Root, Context>) throws -> Void) throws {
        let builder = SchemaBuilder<Root, Context>()
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
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) throws -> Map {
        guard Root.self is Void.Type else {
            throw GraphQLError(
                message: "Root value is required."
            )
        }

        guard Context.self is Void.Type else {
            throw GraphQLError(
                message: "Context value is required."
            )
        }

        return try graphql(
            schema: schema,
            request: request,
            variableValues: variables,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        rootValue: Root,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) throws -> Map {
        guard Context.self is Void.Type else {
            throw GraphQLError(
                message: "Context value is required."
            )
        }

        return try graphql(
            schema: schema,
            request: request,
            rootValue: rootValue,
            variableValues: variables,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        context: Context,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) throws -> Map {
        guard Root.self is Void.Type else {
            throw GraphQLError(
                message: "Root value is required."
            )
        }
        
        return try graphql(
            schema: schema,
            request: request,
            contextValue: context,
            variableValues: variables,
            operationName: operationName
        )
    }

    public func execute(
        request: String,
        rootValue: Root,
        context: Context,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) throws -> Map {
        return try graphql(
            schema: schema,
            request: request,
            rootValue: rootValue,
            contextValue: context,
            variableValues: variables,
            operationName: operationName
        )
    }
}
