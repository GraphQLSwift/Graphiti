import GraphQL
import Runtime
import RxSwift

public class SubscriptionField<ObjectType, Context, SubscriptionType, FieldType, Arguments : Decodable> : FieldComponent<ObjectType, Context> {
    let name: String
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: GraphQLFieldResolve
    let subscribe: GraphQLFieldResolve
    
    override func field(typeProvider: TypeProvider) throws -> (String, GraphQLField) {
        let field = GraphQLField(
            type: try typeProvider.getOutputType(from: FieldType.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: try arguments(typeProvider: typeProvider),
            resolve: resolve,
            subscribe: subscribe
        )
        
        return (name, field)
    }
    
    func arguments(typeProvider: TypeProvider) throws -> GraphQLArgumentConfigMap {
        var map: GraphQLArgumentConfigMap = [:]
        
        for argument in arguments {
            let (name, argument) = try argument.argument(typeProvider: typeProvider)
            map[name] = argument
        }
        
        return map
    }
    
    init(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        resolve: @escaping GraphQLFieldResolve,
        subscribe: @escaping GraphQLFieldResolve
    ) {
        self.name = name
        self.arguments = arguments
        self.resolve = resolve
        self.subscribe = subscribe
    }

    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        asyncSubscribe: @escaping AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>
    ) {
        let resolve: GraphQLFieldResolve = { source, arguments, context, eventLoopGroup, _ in
            guard let s = source as? SubscriptionType else {
                throw GraphQLError(message: "Expected source type \(ObjectType.self) but got \(type(of: source))")
            }
            
            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
            }
        
            let a = try MapDecoder().decode(Arguments.self, from: arguments)
            return try asyncResolve(s)(c, a, eventLoopGroup).map({ $0 })
        }
        
        let subscribe: GraphQLFieldResolve = { source, arguments, context, eventLoopGroup, _ in
            guard let s = source as? ObjectType else {
                throw GraphQLError(message: "Expected source type \(ObjectType.self) but got \(type(of: source))")
            }
        
            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
            }
        
            let a = try MapDecoder().decode(Arguments.self, from: arguments)
            return try asyncSubscribe(s)(c, a, eventLoopGroup).map({ $0 })
        }
        self.init(name: name, arguments: arguments, resolve: resolve, subscribe: subscribe)
    }
    
    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        simpleAsyncResolve: @escaping SimpleAsyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        simpleAsyncSubscribe: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>
    ) {
        let asyncResolve: AsyncResolve<SubscriptionType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncResolve(type)(context, arguments).hop(to: group.next())
            }
        }
        
        let asyncSubscribe: AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>> = { type in
            { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try simpleAsyncSubscribe(type)(context, arguments).hop(to: group.next())
            }
        }
        self.init(name: name, arguments: arguments, asyncResolve: asyncResolve, asyncSubscribe: asyncSubscribe)
    }
    
    convenience init<ResolveType>(
        name: String,
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        syncSubscribe: @escaping SyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>
    ) {
        let asyncResolve: AsyncResolve<SubscriptionType, Context, Arguments, ResolveType> = { type in
            { context, arguments, group in
                let result = try syncResolve(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
            }
        }
        
        let asyncSubscribe: AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>> = { type in
            { context, arguments, group in
                let result = try syncSubscribe(type)(context, arguments)
                return group.next().makeSucceededFuture(result)
            }
        }
        self.init(name: name, arguments: arguments, asyncResolve: asyncResolve, asyncSubscribe: asyncSubscribe)
    }
}

// MARK: AsyncResolve Initializers

public extension SubscriptionField where FieldType : Encodable {
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<SubscriptionType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], asyncResolve: function, asyncSubscribe: subFunc)
    }
    
    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<SubscriptionType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), asyncResolve: function, asyncSubscribe: subFunc)
    }
}

public extension SubscriptionField {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], asyncResolve: function, asyncSubscribe: subFunc)
    }
    
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), asyncResolve: function, asyncSubscribe: subFunc)
    }
}

// MARK: SimpleAsyncResolve Initializers

public extension SubscriptionField where FieldType : Encodable {
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SubscriptionType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], simpleAsyncResolve: function, simpleAsyncSubscribe: subFunc)
    }
    
    convenience init(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SubscriptionType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), simpleAsyncResolve: function, simpleAsyncSubscribe: subFunc)
    }
}

public extension SubscriptionField {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        atSub subFunc: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], simpleAsyncResolve: function, simpleAsyncSubscribe: subFunc)
    }
    
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SimpleAsyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        atSub subFunc: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), simpleAsyncResolve: function, simpleAsyncSubscribe: subFunc)
    }
}

// MARK: SyncResolve Initializers

public extension SubscriptionField where FieldType : Encodable {
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<SubscriptionType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], syncResolve: function, syncSubscribe: subFunc)
    }
    
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<SubscriptionType, Context, Arguments, FieldType>,
        atSub subFunc: @escaping SyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function, syncSubscribe: subFunc)
    }
}

public extension SubscriptionField {
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        atSub subFunc: @escaping SyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(name: name, arguments: [argument()], syncResolve: function, syncSubscribe: subFunc)
    }
    
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping SyncResolve<SubscriptionType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        atSub subFunc: @escaping SyncResolve<ObjectType, Context, Arguments, Observable<SubscriptionType>>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>] = {[]}
    ) {
        self.init(name: name, arguments: arguments(), syncResolve: function, syncSubscribe: subFunc)
    }
}

// TODO Determine if we can use keypaths to initialize

// MARK: Keypath Initializers

//public extension SubscriptionField where Arguments == NoArguments {
//    convenience init(
//        _ name: String,
//        at keyPath: KeyPath<ObjectType, FieldType>
//    ) {
//        let syncResolve: SyncResolve<SubscriptionType, Context, Arguments, ResolveType> = { type in
//            { context, _ in
//                type[keyPath: keyPath]
//            }
//        }
//
//        self.init(name: name, arguments: [], syncResolve: syncResolve)
//    }
//}
//
//public extension SubscriptionField where Arguments == NoArguments {
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
//}
