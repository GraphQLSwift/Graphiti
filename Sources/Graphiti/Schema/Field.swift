import GraphQL
import NIO
import Runtime

//public protocol InputType  : Decodable {}
//public protocol OutputType : Encodable {}
//public protocol ArgumentType : InputType {}

public struct NoArguments : Decodable {
    init() {}
}

public protocol FieldKeyProvider {
    associatedtype FieldKey : RawRepresentable where FieldKey.RawValue == String
}

public typealias SyncResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
)  -> (
    _ context: Context,
    _ arguments: Arguments
) throws -> ResolveType

public typealias AsyncResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
)  -> (
    _ context: Context,
    _ arguments: Arguments,
    _ eventLoopGroup: EventLoopGroup
) throws -> EventLoopFuture<ResolveType>

public class Field<ObjectType, FieldKey : RawRepresentable, Context, Arguments : Decodable, FieldType, ResolveType> : ObjectTypeComponent<ObjectType, FieldKey, Context>, Descriptable where FieldKey.RawValue == String {
    let name: String
    let resolve: GraphQLFieldResolve
    var description: String? = nil
    var argumentsDescriptions: [String: String] = [:]
    var argumentsDefaultValues: [String: Map] = [:]
    var deprecationReason: String? = nil
    
    override func fields(provider: TypeProvider) throws -> GraphQLFieldMap {
        let (name, field) = try self.field(provider: provider)
        return [name: field]
    }
    
    override func field(provider: TypeProvider) throws -> (String, GraphQLField) {
        let field = GraphQLField(
            type: try provider.getOutputType(from: FieldType.self, field: name),
            description: self.description,
            deprecationReason: self.deprecationReason,
            args: try self.arguments(provider: provider),
            resolve: self.resolve
        )
        
        return (name, field)
    }
    
    func arguments(provider: TypeProvider) throws -> [String: GraphQLArgument] {
        var arguments: [String: GraphQLArgument] = [:]
        let info = try typeInfo(of: Arguments.self)
        
        for property in info.properties {
            if case let propertyType as Decodable.Type = property.type {
                arguments[property.name] = GraphQLArgument(
                    type: try provider.getInputType(from: propertyType, field: name),
                    description: self.argumentsDescriptions[property.name],
                    defaultValue: self.argumentsDefaultValues[property.name]
                )
            }
        }
        
        return arguments
    }
    
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    public func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
    
    public func argument<Argument>(_ name: FieldKey, at keyPath: KeyPath<Arguments, Argument>, description: String) -> Self {
        self.argumentsDescriptions[name.rawValue] = description
        return self
    }
    
    public func argument<Argument : Encodable>(_ name: FieldKey, at keyPath: KeyPath<Arguments, Argument>, defaultValue: Argument) -> Self {
        self.argumentsDefaultValues[name.rawValue] = try! MapEncoder().encode(defaultValue)
        return self
    }
    
    init(
        name: String,
        resolve: @escaping GraphQLFieldResolve
    ) {
        self.name = name
        self.resolve = resolve
    }
}

extension Field {
    convenience init(
        name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let name = name
        
        let resolve: GraphQLFieldResolve = { source, arguments, context, eventLoopGroup, _ in
            guard let s = source as? ObjectType else {
                throw GraphQLError(message: "Expected source type \(ObjectType.self) but got \(type(of: source))")
            }
        
            guard let c = context as? Context else {
                throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
            }
        
            let a = try MapDecoder().decode(Arguments.self, from: arguments)
        
            return  try function(s)(c, a, eventLoopGroup).map({ $0 })
        }
        
        self.init(name: name, resolve: resolve)
    }
    
    convenience init(
        name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) {
        let name = name
        let function: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            return { context, arguments, eventLoopGroup in
                let result = try function(type)(context, arguments)
                return eventLoopGroup.next().newSucceededFuture(result: result)
            }
        }
        
        self.init(name: name, at: function)
    }
}

extension Field where FieldType == ResolveType {
    public convenience init(
        _ name: FieldKey,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>
    )  {
        self.init(name: name.rawValue, at: function)
    }
    
    public convenience init(
        _ name: FieldKey,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>
    )  {
        self.init(name: name.rawValue, at: function)
    }
}

extension Field where Arguments == NoArguments, FieldType == ResolveType {
    public convenience init(
        _ name: FieldKey,
        at keyPath: KeyPath<ObjectType, ResolveType>
    ) {
        self.init(name: name.rawValue) { (type: ObjectType) in
            return { (context: Context, arguments: Arguments) in
                return type[keyPath: keyPath]
            }
        }
    }
}

extension Field where Arguments == NoArguments {
    public convenience init(
        _ name: FieldKey,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    )  {
        self.init(name: name.rawValue, at: function)
    }
    
    public convenience init(
        _ name: FieldKey,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    )  {
        self.init(name: name.rawValue, at: function)
    }
    
    public convenience init(
        _ name: FieldKey,
        at keyPath: KeyPath<ObjectType, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    ) {
        let name = name.rawValue
        
        let function: SyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            return { context, arguments in
                return type[keyPath: keyPath]
            }
        }
        
        self.init(name: name, at: function)
    }
}
