import GraphQL

public class Field<
    ObjectType: Sendable,
    Context: Sendable,
    FieldType: Sendable,
    Arguments: Decodable & Sendable
>: FieldComponent<
    ObjectType,
    Context
> {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<ObjectType, Context, Arguments, (any Sendable)?>

    override func field(
        typeProvider: TypeProvider,
        coders: Coders
    ) throws -> (String, GraphQLField) {
        let resolve = self.resolve
        let field = try GraphQLField(
            type: typeProvider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments(typeProvider: typeProvider, coders: coders),
            resolve: { source, arguments, context, _ in
                guard let s = source as? ObjectType else {
                    throw GraphQLError(
                        message: "Expected source type \(ObjectType.self) but got \(type(of: source))"
                    )
                }

                guard let c = context as? Context else {
                    throw GraphQLError(
                        message: "Expected context type \(Context.self) but got \(type(of: context))"
                    )
                }

                let a = try coders.decoder.decode(Arguments.self, from: arguments)
                return try await resolve(s)(c, a)
            }
        )

        return (name, field)
    }

    func arguments(typeProvider: TypeProvider, coders: Coders) throws -> GraphQLArgumentConfigMap {
        var map: GraphQLArgumentConfigMap = [:]

        for argument in arguments {
            let (name, argument) = try argument.argument(typeProvider: typeProvider, coders: coders)
            map[name] = argument
        }

        return map
    }

    init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        resolve: @escaping AsyncResolve<ObjectType, Context, Arguments, (any Sendable)?>
    ) {
        self.name = name
        self.arguments = arguments
        self.resolve = resolve
    }

    convenience init<ResolveType: Sendable>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, (any Sendable)?> = { type in
            { context, arguments in
                try await asyncResolve(type)(context, arguments)
            }
        }
        self.init(name: name, arguments: arguments, resolve: resolve)
    }

    convenience init<ResolveType: Sendable>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments in
                try syncResolve(type)(context, arguments)
            }
        }

        self.init(name: name, arguments: arguments, asyncResolve: asyncResolve)
    }
}

// MARK: AsyncResolve Initializers

public extension Field {
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], asyncResolve: function)
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), asyncResolve: function)
    }
}

public extension Field {
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], syncResolve: function)
    }

    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function)
    }
}

// MARK: Keypath Initializers

public extension Field where Arguments == NoArguments {
    convenience init(
        _ name: String,
        at keyPath: KeyPath<ObjectType, FieldType>
    ) {
        let syncResolve: SyncResolve<ObjectType, Context, NoArguments, FieldType> = { type in
            { _, _ in
                type[keyPath: keyPath]
            }
        }

        self.init(name: name, arguments: [], syncResolve: syncResolve)
    }
}

// We must conform KeyPath to unchecked sendable to allow keypath-based resolvers.
extension KeyPath: @retroactive @unchecked Sendable {}
