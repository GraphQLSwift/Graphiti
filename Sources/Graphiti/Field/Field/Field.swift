import GraphQL
import Runtime

public class Field<ObjectType, Context, FieldType, Arguments : Decodable> : FieldComponent<ObjectType, Context> {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: GraphQLFieldResolve
    
    override func field(provider: TypeProvider) throws -> (String, GraphQLField) {
        let field = GraphQLField(
            type: try provider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: try arguments(provider: provider),
            resolve: resolve
        )
        
        return (name, field)
    }
    
    func arguments(provider: TypeProvider) throws -> GraphQLArgumentConfigMap {
        var map: GraphQLArgumentConfigMap = [:]
        
        for argument in arguments {
            let (name, argument) = try argument.argument(provider: provider)
            map[name] = argument
        }
        
        return map
    }
    
    init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        resolve: @escaping GraphQLFieldResolve
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
        let resolve: GraphQLFieldResolve = { source, arguments, context, eventLoopGroup, _ in
            guard let s = source as? ObjectType else {
                throw GraphQLError(message: "Expected source type \(ObjectType.self) but got \(type(of: source))")
            }
        
            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
            }
        
            let a = try MapDecoder().decode(Arguments.self, from: arguments)
            return  try asyncResolve(s)(c, a, eventLoopGroup).map({ $0 })
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
}

// MARK: AsyncResolve Initializers

public extension Field where FieldType : Encodable {
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        _ arguments: ArgumentComponent<Arguments>...
    ) {
        self.init(name: name, arguments: arguments, asyncResolve: function)
    }
}

public extension Field {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        _ arguments: ArgumentComponent<Arguments>...
    ) {
        self.init(name: name, arguments: arguments, asyncResolve: function)
    }
}

// MARK: SimpleAsyncResolve Initializers

public extension Field where FieldType : Encodable {
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, FieldType>,
        _ arguments: ArgumentComponent<Arguments>...
    ) {
        self.init(name: name, arguments: arguments, simpleAsyncResolve: function)
    }
}

public extension Field {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        _ arguments: ArgumentComponent<Arguments>...
    ) {
        self.init(name: name, arguments: arguments, simpleAsyncResolve: function)
    }
}

// MARK: SyncResolve Initializers

public extension Field where FieldType : Encodable {
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        _ arguments: ArgumentComponent<Arguments>...
    ) {
        self.init(name: name, arguments: arguments, syncResolve: function)
    }
}

public extension Field {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        _ arguments: ArgumentComponent<Arguments>...
    ) {
        self.init(name: name, arguments: arguments, syncResolve: function)
    }
}

// MARK: Keypath Initializers

public extension Field where Arguments == NoArguments {
    convenience init(
        _ name: String,
        at keyPath: KeyPath<ObjectType, FieldType>
    ) {
        let syncResolve: SyncResolve<ObjectType, Context, NoArguments, FieldType> = { type in
            { context, _ in
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
        as: FieldType.Type
    ) {
        let syncResolve: SyncResolve<ObjectType, Context, NoArguments, ResolveType> = { type in
            return { context, _ in
                return type[keyPath: keyPath]
            }
        }
        
        self.init(name: name, arguments: [], syncResolve: syncResolve)
    }
}
