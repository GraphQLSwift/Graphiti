import GraphQL
import NIO

public class Key<ObjectType, Resolver, Context, Arguments: Codable>: KeyComponent<ObjectType, Resolver, Context> {
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<Resolver, Context, Arguments, ObjectType?>
    
    override func mapMatchesArguments(_ map: Map, coders: Coders) -> Bool {
        let args = try? coders.decoder.decode(Arguments.self, from: map)
        return args != nil
    }
    
    override func resolveMap(
        resolver: Resolver,
        context: Context,
        map: Map,
        eventLoopGroup: EventLoopGroup,
        coders: Coders
    ) throws -> EventLoopFuture<Any?> {
        let arguments = try coders.decoder.decode(Arguments.self, from: map)
        return try self.resolve(resolver)(context, arguments, eventLoopGroup).map { $0 as Any? }
    }
    
    override func validate(againstFields fieldNames: [String], typeProvider: TypeProvider, coders: Coders) throws {
        // Ensure that every argument is included in the provided field list
        for (name, argument) in try arguments(typeProvider: typeProvider, coders: coders) {
            if !fieldNames.contains(name) {
                throw GraphQLError(message: "Argument name not found in type fields: \(name)")
            }
        }
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
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<Resolver, Context, Arguments, ObjectType?>
    ) {
        self.arguments = arguments
        self.resolve = asyncResolve
    }

    convenience init(
        arguments: [ArgumentComponent<Arguments>],
        simpleAsyncResolve: @escaping SimpleAsyncResolve<
            Resolver,
            Context,
            Arguments,
            ObjectType?
        >
    ) {
        let asyncResolve: AsyncResolve<Resolver, Context, Arguments, ObjectType?> = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncResolve(type)(context, arguments).hop(to: group.next())
            }
        }

        self.init(arguments: arguments, asyncResolve: asyncResolve)
    }

    convenience init(
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<Resolver, Context, Arguments, ObjectType?>
    ) {
        let asyncResolve: AsyncResolve<Resolver, Context, Arguments, ObjectType?> = { type in
            { context, arguments, group in
                let result = try syncResolve(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
            }
        }

        self.init(arguments: arguments, asyncResolve: asyncResolve)
    }
}

// MARK: AsyncResolve Initializers

public extension Key {
    convenience init(
        at function: @escaping AsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(arguments: [argument()], asyncResolve: function)
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(arguments: arguments(), asyncResolve: function)
    }
}

// MARK: SimpleAsyncResolve Initializers

public extension Key {
    convenience init(
        at function: @escaping SimpleAsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(arguments: [argument()], simpleAsyncResolve: function)
    }

    convenience init(
        at function: @escaping SimpleAsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(arguments: arguments(), simpleAsyncResolve: function)
    }
}

// MARK: SyncResolve Initializers

public extension Key {
    convenience init(
        at function: @escaping SyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(arguments: [argument()], syncResolve: function)
    }

    convenience init(
        at function: @escaping SyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(arguments: arguments(), syncResolve: function)
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

    public extension Key {
        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init(
            arguments: [ArgumentComponent<Arguments>],
            concurrentResolve: @escaping ConcurrentResolve<
                Resolver,
                Context,
                Arguments,
                ObjectType?
            >
        ) {
            let asyncResolve: AsyncResolve<Resolver, Context, Arguments, ObjectType?> = { type in
                { context, arguments, eventLoopGroup in
                    let promise = eventLoopGroup.next().makePromise(of: ObjectType?.self)
                    promise.completeWithTask {
                        try await concurrentResolve(type)(context, arguments)
                    }
                    return promise.futureResult
                }
            }
            self.init(arguments: arguments, asyncResolve: asyncResolve)
        }
    }

    // MARK: ConcurrentResolve Initializers

    public extension Key {
        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init(
            at function: @escaping ConcurrentResolve<Resolver, Context, Arguments, ObjectType>,
            @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
        ) {
            self.init(arguments: [argument()], concurrentResolve: function)
        }

        @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
        convenience init(
            at function: @escaping ConcurrentResolve<Resolver, Context, Arguments, ObjectType>,
            @ArgumentComponentBuilder<Arguments> _ arguments: ()
                -> [ArgumentComponent<Arguments>] = { [] }
        ) {
            self.init(arguments: arguments(), concurrentResolve: function)
        }
    }

#endif
