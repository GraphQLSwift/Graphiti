import GraphQL
import Runtime

public class Field<ObjectType, Keys : RawRepresentable, Context, Arguments : Decodable, FieldType, ResolveType> : FieldComponent<ObjectType, Keys, Context> where Keys.RawValue == String {
    let name: String
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
    
    func arguments(provider: TypeProvider) throws -> [String: GraphQLArgument] {
        var arguments: [String: GraphQLArgument] = [:]
        let info = try typeInfo(of: Arguments.self)
        
        for property in info.properties {
            if case let propertyType as Decodable.Type = property.type {
                arguments[property.name] = GraphQLArgument(
                    type: try provider.getInputType(from: propertyType, field: name),
                    description: argumentsDescriptions[property.name],
                    defaultValue: try argumentsDefaultValues[property.name].map {
                        try MapEncoder().encode($0)
                    }
                )
            }
        }
        
        return arguments
    }
    
    init(
        name: String,
        resolve: @escaping GraphQLFieldResolve
    ) {
        self.name = name
        self.resolve = resolve
    }

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

