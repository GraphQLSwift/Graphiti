import GraphQL
import NIO

public class Field<ObjectType, Context, FieldType, Arguments: Decodable>: FieldComponent<
    ObjectType,
    Context
> {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<ObjectType, Context, Arguments, Any?>

    override func field(
        typeProvider: TypeProvider,
        coders: Coders
    ) throws -> (String, GraphQLField) {
        let field = try GraphQLField(
            type: typeProvider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments(typeProvider: typeProvider, coders: coders),
            resolve: { source, arguments, context, eventLoopGroup, _ in
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
                return try self.resolve(s)(c, a, eventLoopGroup)
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
        resolve: @escaping AsyncResolve<ObjectType, Context, Arguments, Any?>
    ) {
        self.name = name
        self.arguments = arguments
        self.resolve = resolve
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, Any?> = { type in
            { context, arguments, eventLoopGroup in
                try asyncResolve(type)(context, arguments, eventLoopGroup).map { $0 as Any? }
            }
        }
        self.init(name: name, arguments: arguments, resolve: resolve)
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        simpleAsyncResolve: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            ResolveType
        >
    ) {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncResolve(type)(context, arguments).hop(to: group.next())
            }
        }

        self.init(name: name, arguments: arguments, asyncResolve: asyncResolve)
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                let result = try syncResolve(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
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
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], asyncResolve: function)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), asyncResolve: function)
    }
}

// MARK: SimpleAsyncResolve Initializers

public extension Field {
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], simpleAsyncResolve: function)
    }

    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), simpleAsyncResolve: function)
    }
}

public extension Field {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], simpleAsyncResolve: function)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), simpleAsyncResolve: function)
    }
}

// MARK: SyncResolve Initializers

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

public extension Field {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], syncResolve: function)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
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

public extension Field where Arguments == NoArguments {
    convenience init<ResolveType>(
        _ name: String,
        at keyPath: KeyPath<ObjectType, ResolveType>,
        as _: FieldType.Type
    ) {
        let syncResolve: SyncResolve<ObjectType, Context, NoArguments, ResolveType> = { type in
            { _, _ in
                type[keyPath: keyPath]
            }
        }

        self.init(name: name, arguments: [], syncResolve: syncResolve)
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

    public extension Field {
        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init<ResolveType>(
            name: String,
            arguments: [ArgumentComponent<Arguments>],
            concurrentResolve: @escaping ConcurrentResolve<
                ObjectType,
                Context,
                Arguments,
                ResolveType
            >
        ) {
            let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
                { context, arguments, eventLoopGroup in
                    let promise = eventLoopGroup.next().makePromise(of: ResolveType.self)
                    promise.completeWithTask {
                        try await concurrentResolve(type)(context, arguments)
                    }
                    return promise.futureResult
                }
            }
            self.init(name: name, arguments: arguments, asyncResolve: asyncResolve)
        }
    }

    // MARK: ConcurrentResolve Initializers

    public extension Field {
        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init(
            _ name: String,
            at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, FieldType>,
            @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
        ) {
            self.init(name: name, arguments: [argument()], concurrentResolve: function)
        }

        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init(
            _ name: String,
            at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, FieldType>,
            @ArgumentComponentBuilder<Arguments> _ arguments: ()
                -> [ArgumentComponent<Arguments>] = { [] }
        ) {
            self.init(name: name, arguments: arguments(), concurrentResolve: function)
        }
    }

    public extension Field {
        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init<ResolveType>(
            _ name: String,
            at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, ResolveType>,
            as: FieldType.Type,
            @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
        ) {
            self.init(name: name, arguments: [argument()], concurrentResolve: function)
        }

        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init<ResolveType>(
            _ name: String,
            at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, ResolveType>,
            as: FieldType.Type,
            @ArgumentComponentBuilder<Arguments> _ arguments: ()
                -> [ArgumentComponent<Arguments>] = { [] }
        ) {
            self.init(name: name, arguments: arguments(), concurrentResolve: function)
        }
    }

#endif
