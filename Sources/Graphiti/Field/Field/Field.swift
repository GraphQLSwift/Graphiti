import GraphQL
import NIO

public class Field<ObjectType, Context, FieldType, Arguments>: FieldComponent<ObjectType, Context> where Arguments: Decodable {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<ObjectType, Context, Arguments, Any?>
    
    override func field(typeProvider: TypeProvider, coders: Coders) throws -> (String, GraphQLField) {
        let field = GraphQLField(
            type: try typeProvider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: try arguments(typeProvider: typeProvider, coders: coders),
            resolve: { source, arguments, context, eventLoopGroup, _ in
                guard let source = source as? ObjectType else {
                    throw GraphQLError(message: "Expected source type \(ObjectType.self) but got \(type(of: source))")
                }
    
                guard let context = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                }
    
                let arguments = try coders.decoder.decode(Arguments.self, from: arguments)
                return try self.resolve(source)(context, arguments, eventLoopGroup)
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
        super.init()
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, Any?> = { type in
            { context, arguments, eventLoopGroup in
                return try asyncResolve(type)(context, arguments, eventLoopGroup).map { $0 as Any? }
            }
        }
        
        self.init(name: name, arguments: arguments, resolve: resolve)
    }
    
    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        simpleAsyncResolve: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>
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
    
    public required init(extendedGraphemeClusterLiteral string: String) {
        fatalError("init(extendedGraphemeClusterLiteral:) has not been implemented")
    }
    
    public required init(unicodeScalarLiteral string: String) {
        fatalError("init(unicodeScalarLiteral:) has not been implemented")
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        fatalError("init(stringLiteral:) has not been implemented")
    }
}

// MARK: AsyncResolve Initializers

public extension Field where FieldType : Encodable {
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], asyncResolve: function)
    }
    
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), asyncResolve: function)
    }
}

public extension Field {
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], asyncResolve: function)
    }
    
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), asyncResolve: function)
    }
}

// MARK: SimpleAsyncResolve Initializers

public extension Field where FieldType : Encodable {
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], simpleAsyncResolve: function)
    }
    
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), simpleAsyncResolve: function)
    }
}

public extension Field {
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], simpleAsyncResolve: function)
    }
    
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), simpleAsyncResolve: function)
    }
}

// MARK: SyncResolve Initializers

public extension Field where FieldType : Encodable {
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], syncResolve: function)
    }
        
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function)
    }
}

public extension Field {
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], syncResolve: function)
    }
    
    @available(*, deprecated, message: "Use the initializer that takes a key path to a `Resolve` function instead.")
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function)
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

// MARK: Keypath Initializers

public typealias Resolve<Context, Arguments, ResolveType> = (
    _ context: Context,
    _ arguments: Arguments
) async throws -> ResolveType

@available(macOS 12, *)
public extension Field {
    convenience init(
        _ name: String,
        at keyPath: KeyPath<ObjectType, Resolve<Context, Arguments, FieldType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>]
    ) {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, group in
                let promise = group.next().makePromise(of: FieldType.self)
                
                promise.completeWithTask {
                    try await type[keyPath: keyPath](context, arguments)
                }
                    
                return promise.futureResult
            }
        }
        
        self.init(name: name, arguments: arguments(), asyncResolve: asyncResolve)
    }
}

@available(macOS 12, *)
public extension Field {
    convenience init<ResolveType>(
        _ name: String,
        at keyPath: KeyPath<ObjectType, Resolve<Context, Arguments, ResolveType>>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>]
    ) where ResolveType: Encodable {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                let promise = group.next().makePromise(of: ResolveType.self)
                
                promise.completeWithTask {
                    try await type[keyPath: keyPath](context, arguments)
                }
                    
                return promise.futureResult
            }
        }
        
        self.init(name: name, arguments: arguments(), asyncResolve: asyncResolve)
    }
}

@available(macOS 12, *)
public extension Field where Arguments == NoArguments {
    convenience init(
        _ name: String,
        at keyPath: KeyPath<ObjectType, Resolve<Context, Void, FieldType>>
    ) {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, _, group in
                let promise = group.next().makePromise(of: FieldType.self)
                
                promise.completeWithTask {
                    try await type[keyPath: keyPath](context, ())
                }
                    
                return promise.futureResult
            }
        }
        
        self.init(name: name, arguments: [], asyncResolve: asyncResolve)
    }
}

@available(macOS 12, *)
public extension Field where Arguments == NoArguments {
    convenience init<ResolveType>(
        _ name: String,
        at keyPath: KeyPath<ObjectType, Resolve<Context, Void, ResolveType>>,
        as: FieldType.Type
    ) {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, _, group in
                let promise = group.next().makePromise(of: ResolveType.self)
                
                promise.completeWithTask {
                    try await type[keyPath: keyPath](context, ())
                }
                    
                return promise.futureResult
            }
        }
        
        self.init(name: name, arguments: [], asyncResolve: asyncResolve)
    }
}

#endif

public extension Field where Arguments == NoArguments, FieldType: Encodable {
    convenience init(
        _ name: String,
        of: FieldType.Type = FieldType.self,
        at keyPath: KeyPath<ObjectType, FieldType>
    ) {
        let syncResolve: SyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { _, _ in
                type[keyPath: keyPath]
            }
        }
        
        self.init(name: name, arguments: [], syncResolve: syncResolve)
    }
}

public extension Field where Arguments == NoArguments {
    @available(*, deprecated, message: "Use the Field.init(_:of:at:) instead.")
    convenience init<ResolveType>(
        _ name: String,
        at keyPath: KeyPath<ObjectType, ResolveType>,
        as: FieldType.Type
    ) where ResolveType: Encodable {
        let syncResolve: SyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { _, _ in
                type[keyPath: keyPath]
            }
        }
        
        self.init(name: name, arguments: [], syncResolve: syncResolve)
    }
    
    convenience init<ResolveType>(
        _ name: String,
        of: FieldType.Type,
        at keyPath: KeyPath<ObjectType, ResolveType>
    ) where ResolveType: Encodable {
        let syncResolve: SyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { _, _ in
                type[keyPath: keyPath]
            }
        }
        
        self.init(name: name, arguments: [], syncResolve: syncResolve)
    }
}
