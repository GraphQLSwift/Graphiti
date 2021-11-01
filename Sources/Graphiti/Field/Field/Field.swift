import GraphQL
import NIO

public class Field<ObjectType, Context, FieldType, Arguments>: FieldComponent<ObjectType, Context> where Arguments: Decodable {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    var resolve: AsyncResolve<ObjectType, Context, Arguments, Any?>
    private var directives: [FieldDefinitionDirective] = []
    
    override func field(typeProvider: TypeProvider, coders: Coders) throws -> (String, GraphQLField) {
        let arguments = try arguments(typeProvider: typeProvider, coders: coders)
        applyDirectives(typeProdiver: typeProvider, arguments: arguments)
        
        let field = GraphQLField(
            type: try typeProvider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments,
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
    
    func applyDirectives(typeProdiver: TypeProvider, arguments: GraphQLArgumentConfigMap) {
        for directive in directives {
            #warning("TODO: Check if directive exists schema")
            #warning("TODO: Check for repeatable")
            
            let oldResolve = self.resolve
            
            var fieldConfiguration = FieldConfiguration(
                name: name,
                description: description,
                deprecationReason: deprecationReason,
                arguments: arguments.map { name, argument in
                    ArgumentConfiguration(
                        name: name,
                        defaultValue: argument.defaultValue
                    )
                },
                resolve: { object in
                    { context, arguments, group in
                        try oldResolve(object as! ObjectType)(context as! Context, arguments as! Arguments, group)
                    }
                }
            )
            
            directive.fieldDefinition(&fieldConfiguration)
            
            self.description = fieldConfiguration.description
            self.deprecationReason = fieldConfiguration.deprecationReason
            #warning("TODO: update arguments")
            
            let newResolve = fieldConfiguration.resolve
            
            self.resolve = { object in
                { context, arguments, group in
                    try newResolve(object)(context, arguments, group)
                }
            }
        }
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
        of type: FieldType.Type = FieldType.self,
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
        of type: FieldType.Type,
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

// MARK: Directive

extension Field {
    func directive<Directive>(_ directive: Directive) -> Field where Directive: FieldDefinitionDirective {
        directives.append(directive)
        return self
    }
}
