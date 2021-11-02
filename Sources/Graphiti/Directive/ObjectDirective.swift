import GraphQL

#warning("TODO: Move to InterfaceDirective")
public struct InterfaceConfiguration {
    public let name: String
    public var description: String?
    public var fields: [FieldConfiguration]
    public var interfaces: [InterfaceConfiguration]
}

extension InterfaceConfiguration {
    init(_ interface: GraphQLInterfaceType) {
        self.name = interface.name
        self.description = interface.description
        self.fields = interface.fields.map(FieldConfiguration.init)
        self.interfaces = interface.interfaces.map(InterfaceConfiguration.init)
    }
}

public struct ObjectConfiguration {
    public let name: String
    public var description: String?
    public var fields: [FieldConfiguration]
    public var interfaces: [InterfaceConfiguration]
    fileprivate let isTypeOf: GraphQLIsTypeOf?
}

extension ObjectConfiguration {
    init(_ objectType: GraphQLObjectType) {
        self.name = objectType.name
        self.description = objectType.description
        self.fields = objectType.fields.map(FieldConfiguration.init)
        self.interfaces = objectType.interfaces.map(InterfaceConfiguration.init)
        self.isTypeOf = objectType.isTypeOf
        
    }
}

extension GraphQLObjectType {
    convenience init(_ configuration: ObjectConfiguration) throws {
        try self.init(
            name: configuration.name,
            description: configuration.description,
            fields: [:], //configuration.fields.reduce(into: [:]) { result, configuration in
//                result[configuration.name] = GraphQLFieldDefinition(configuration)
//            },
            interfaces: [], // configuration.interfaces.map(GraphQLInterfaceType.init),
            isTypeOf: configuration.isTypeOf
        )
    }
}

public struct ConfigureObject {
    let configure: (inout ObjectConfiguration) -> Void
    
    init(configure: @escaping (inout ObjectConfiguration) -> Void) {
        self.configure = configure
    }
}

public protocol ObjectDirective {
    var object: ConfigureObject { get }
}
