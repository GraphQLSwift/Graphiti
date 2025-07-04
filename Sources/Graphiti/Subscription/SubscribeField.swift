import GraphQL
import NIO

// Subscription resolver MUST return an Observer<Any>, not a specific type, due to lack of support for covariance generics in Swift

public class SubscriptionField<
    SourceEventType,
    ObjectType,
    Context,
    FieldType,
    Arguments: Decodable
>: FieldComponent<ObjectType, Context> {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<SourceEventType, Context, Arguments, Any?>
    let subscribe: AsyncResolve<ObjectType, Context, Arguments, EventStream<SourceEventType>>

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
                guard let _source = source as? SourceEventType else {
                    throw GraphQLError(
                        message: "Expected source type \(SourceEventType.self) but got \(type(of: source))"
                    )
                }

                guard let _context = context as? Context else {
                    throw GraphQLError(
                        message: "Expected context type \(Context.self) but got \(type(of: context))"
                    )
                }

                let args = try coders.decoder.decode(Arguments.self, from: arguments)
                return try self.resolve(_source)(_context, args, eventLoopGroup)
            },
            subscribe: { source, arguments, context, eventLoopGroup, _ in
                guard let _source = source as? ObjectType else {
                    throw GraphQLError(
                        message: "Expected source type \(ObjectType.self) but got \(type(of: source))"
                    )
                }

                guard let _context = context as? Context else {
                    throw GraphQLError(
                        message: "Expected context type \(Context.self) but got \(type(of: context))"
                    )
                }

                let args = try coders.decoder.decode(Arguments.self, from: arguments)
                return try self.subscribe(_source)(_context, args, eventLoopGroup)
                    .map { $0.map { $0 as Any } }
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
        resolve: @escaping AsyncResolve<SourceEventType, Context, Arguments, Any?>,
        subscribe: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        self.name = name
        self.arguments = arguments
        self.resolve = resolve
        self.subscribe = subscribe
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        asyncSubscribe: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let resolve: AsyncResolve<SourceEventType, Context, Arguments, Any?> = { type in
            { context, arguments, eventLoopGroup in
                try asyncResolve(type)(context, arguments, eventLoopGroup).map { $0 }
            }
        }
        self.init(name: name, arguments: arguments, resolve: resolve, subscribe: asyncSubscribe)
    }

    convenience init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        as _: FieldType.Type,
        asyncSubscribe: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let resolve: AsyncResolve<SourceEventType, Context, Arguments, Any?> = { source in
            { _, _, eventLoopGroup in
                eventLoopGroup.next().makeSucceededFuture(source)
            }
        }
        self.init(name: name, arguments: arguments, resolve: resolve, subscribe: asyncSubscribe)
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        simpleAsyncResolve: @escaping SimpleAsyncResolve<
            SourceEventType,
            Context,
            Arguments,
            ResolveType
        >,
        simpleAsyncSubscribe: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let asyncResolve: AsyncResolve<SourceEventType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncResolve(type)(context, arguments).hop(to: group.next())
            }
        }

        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        > = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncSubscribe(type)(context, arguments).hop(to: group.next())
            }
        }
        self.init(
            name: name,
            arguments: arguments,
            asyncResolve: asyncResolve,
            asyncSubscribe: asyncSubscribe
        )
    }

    convenience init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        as: FieldType.Type,
        simpleAsyncSubscribe: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        > = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncSubscribe(type)(context, arguments).hop(to: group.next())
            }
        }
        self.init(name: name, arguments: arguments, as: `as`, asyncSubscribe: asyncSubscribe)
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        syncSubscribe: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let asyncResolve: AsyncResolve<SourceEventType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                let result = try syncResolve(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
            }
        }

        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        > = { type in
            { context, arguments, group in
                let result = try syncSubscribe(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
            }
        }
        self.init(
            name: name,
            arguments: arguments,
            asyncResolve: asyncResolve,
            asyncSubscribe: asyncSubscribe
        )
    }

    convenience init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        as: FieldType.Type,
        syncSubscribe: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        > = { type in
            { context, arguments, group in
                let result = try syncSubscribe(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
            }
        }
        self.init(name: name, arguments: arguments, as: `as`, asyncSubscribe: asyncSubscribe)
    }
}

// MARK: AsyncResolve Initializers

public extension SubscriptionField {
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            asyncResolve: function,
            asyncSubscribe: subFunc
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            asyncResolve: function,
            asyncSubscribe: subFunc
        )
    }
}

public extension SubscriptionField {
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], as: `as`, asyncSubscribe: subFunc)
    }

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), as: `as`, asyncSubscribe: subFunc)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        atSub subFunc: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            asyncResolve: function,
            asyncSubscribe: subFunc
        )
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        atSub subFunc: @escaping AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            asyncResolve: function,
            asyncSubscribe: subFunc
        )
    }
}

// MARK: SimpleAsyncResolve Initializers

public extension SubscriptionField {
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            simpleAsyncResolve: function,
            simpleAsyncSubscribe: subFunc
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            simpleAsyncResolve: function,
            simpleAsyncSubscribe: subFunc
        )
    }
}

public extension SubscriptionField {
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], as: `as`, simpleAsyncSubscribe: subFunc)
    }

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), as: `as`, simpleAsyncSubscribe: subFunc)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        as _: FieldType.Type,
        atSub subFunc: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            simpleAsyncResolve: function,
            simpleAsyncSubscribe: subFunc
        )
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        as _: FieldType.Type,
        atSub subFunc: @escaping SimpleAsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            simpleAsyncResolve: function,
            simpleAsyncSubscribe: subFunc
        )
    }
}

// MARK: SyncResolve Initializers

// '@_disfavoredOverload' is included below because otherwise `SimpleAsyncResolve` initializers also match this signature, causing the
// calls to be ambiguous. We prefer that if an EventLoopFuture is returned from the resolve, that `SimpleAsyncResolve` is matched.

public extension SubscriptionField {
    @_disfavoredOverload
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            syncResolve: function,
            syncSubscribe: subFunc
        )
    }

    @_disfavoredOverload
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function, syncSubscribe: subFunc)
    }
}

public extension SubscriptionField {
    @_disfavoredOverload
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], as: `as`, syncSubscribe: subFunc)
    }

    @_disfavoredOverload
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), as: `as`, syncSubscribe: subFunc)
    }

    @_disfavoredOverload
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        as _: FieldType.Type,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            syncResolve: function,
            syncSubscribe: subFunc
        )
    }

    @_disfavoredOverload
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        as _: FieldType.Type,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function, syncSubscribe: subFunc)
    }
}

public extension SubscriptionField {
    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        concurrentResolve: @escaping ConcurrentResolve<
            SourceEventType,
            Context,
            Arguments,
            ResolveType
        >,
        concurrentSubscribe: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let asyncResolve: AsyncResolve<SourceEventType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                let promise = eventLoopGroup.next().makePromise(of: ResolveType.self)
                promise.completeWithTask {
                    try await concurrentResolve(type)(context, arguments)
                }
                return promise.futureResult
            }
        }
        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        > = { type in
            { context, arguments, eventLoopGroup in
                let promise = eventLoopGroup.next()
                    .makePromise(of: EventStream<SourceEventType>.self)
                promise.completeWithTask {
                    try await concurrentSubscribe(type)(context, arguments)
                }
                return promise.futureResult
            }
        }
        self.init(
            name: name,
            arguments: arguments,
            asyncResolve: asyncResolve,
            asyncSubscribe: asyncSubscribe
        )
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        as: FieldType.Type,
        concurrentSubscribe: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >
    ) {
        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        > = { type in
            { context, arguments, eventLoopGroup in
                let promise = eventLoopGroup.next()
                    .makePromise(of: EventStream<SourceEventType>.self)
                promise.completeWithTask {
                    try await concurrentSubscribe(type)(context, arguments)
                }
                return promise.futureResult
            }
        }
        self.init(name: name, arguments: arguments, as: `as`, asyncSubscribe: asyncSubscribe)
    }
}

// MARK: ConcurrentResolve Initializers

public extension SubscriptionField {
    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init(
        _ name: String,
        at function: @escaping ConcurrentResolve<
            SourceEventType,
            Context,
            Arguments,
            FieldType
        >,
        atSub subFunc: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            concurrentResolve: function,
            concurrentSubscribe: subFunc
        )
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init(
        _ name: String,
        at function: @escaping ConcurrentResolve<
            SourceEventType,
            Context,
            Arguments,
            FieldType
        >,
        atSub subFunc: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            concurrentResolve: function,
            concurrentSubscribe: subFunc
        )
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [arguments()], as: `as`, concurrentSubscribe: subFunc)
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), as: `as`, concurrentSubscribe: subFunc)
    }
}

public extension SubscriptionField {
    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping ConcurrentResolve<
            SourceEventType,
            Context,
            Arguments,
            ResolveType
        >,
        as _: FieldType.Type,
        atSub subFunc: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            concurrentResolve: function,
            concurrentSubscribe: subFunc
        )
    }

    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping ConcurrentResolve<
            SourceEventType,
            Context,
            Arguments,
            ResolveType
        >,
        as _: FieldType.Type,
        atSub subFunc: @escaping ConcurrentResolve<
            ObjectType,
            Context,
            Arguments,
            EventStream<SourceEventType>
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            concurrentResolve: function,
            concurrentSubscribe: subFunc
        )
    }
}

// TODO: Determine if we can use keypaths to initialize

// MARK: Keypath Initializers

// public extension SubscriptionField where Arguments == NoArguments {
//    convenience init(
//        _ name: String,
//        at keyPath: KeyPath<ObjectType, FieldType>
//    ) {
//        let syncResolve: SyncResolve<Any, Context, Arguments, ResolveType> = { type in
//            { context, _ in
//                type[keyPath: keyPath]
//            }
//        }
//
//        self.init(name: name, arguments: [], syncResolve: syncResolve)
//    }
// }
//
// public extension SubscriptionField where Arguments == NoArguments {
//    convenience init<ResolveType>(
//        _ name: String,
//        at keyPath: KeyPath<ObjectType, ResolveType>,
//        as: FieldType.Type
//    ) {
//        let syncResolve: SyncResolve<ObjectType, Context, NoArguments, ResolveType> = { type in
//            return { context, _ in
//                return type[keyPath: keyPath]
//            }
//        }
//
//        self.init(name: name, arguments: [], syncResolve: syncResolve)
//    }
// }
