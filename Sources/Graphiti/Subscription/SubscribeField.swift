import GraphQL

// Subscription resolver MUST return an Observer<Any>, not a specific type, due to lack of support for covariance generics in Swift

public class SubscriptionField<
    SourceEventType,
    ObjectType,
    Context,
    FieldType,
    Arguments: Decodable,
    SubSequence: AsyncSequence
>: FieldComponent<ObjectType, Context> where SubSequence.Element == SourceEventType {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<SourceEventType, Context, Arguments, Any?>
    let subscribe: AsyncResolve<ObjectType, Context, Arguments, SubSequence>

    override func field(
        typeProvider: TypeProvider,
        coders: Coders
    ) throws -> (String, GraphQLField) {
        let field = try GraphQLField(
            type: typeProvider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments(typeProvider: typeProvider, coders: coders),
            resolve: { source, arguments, context, _ in
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
                return try await self.resolve(_source)(_context, args)
            },
            subscribe: { source, arguments, context, _ in
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
                return try await self.subscribe(_source)(_context, args)
                    .map { $0 as Any }
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
            SubSequence
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
            SubSequence
        >
    ) {
        let resolve: AsyncResolve<SourceEventType, Context, Arguments, Any?> = { type in
            { context, arguments in
                try await asyncResolve(type)(context, arguments)
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
            SubSequence
        >
    ) {
        let resolve: AsyncResolve<SourceEventType, Context, Arguments, Any?> = { source in
            { _, _ in
                source
            }
        }
        self.init(name: name, arguments: arguments, resolve: resolve, subscribe: asyncSubscribe)
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<SourceEventType, Context, Arguments, ResolveType>,
        syncSubscribe: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            SubSequence
        >
    ) {
        let asyncResolve: AsyncResolve<SourceEventType, Context, Arguments, ResolveType> = { type in
            { context, arguments in
                try syncResolve(type)(context, arguments)
            }
        }

        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            SubSequence
        > = { type in
            { context, arguments in
                try syncSubscribe(type)(context, arguments)
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
            SubSequence
        >
    ) {
        let asyncSubscribe: AsyncResolve<
            ObjectType,
            Context,
            Arguments,
            SubSequence
        > = { type in
            { context, arguments in
                try syncSubscribe(type)(context, arguments)
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
            SubSequence
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
            SubSequence
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
            SubSequence
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
            SubSequence
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
            SubSequence
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
            SubSequence
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
        at function: @escaping SyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            SubSequence
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

    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<SourceEventType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SyncResolve<
            ObjectType,
            Context,
            Arguments,
            SubSequence
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
            SubSequence
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
            SubSequence
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
            SubSequence
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
            SubSequence
        >,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function, syncSubscribe: subFunc)
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
