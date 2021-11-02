import GraphQL

#warning("TODO: Move to ArgumentDefinitionDirective")
public struct ArgumentConfiguration {
    public let name: String
    public var defaultValue: Map?
}

extension ArgumentConfiguration {
    init(_ argumentDefinition: GraphQLArgumentDefinition) {
        self.name = argumentDefinition.name
        self.defaultValue = argumentDefinition.defaultValue
    }
}

public struct FieldConfiguration {
    public let name: String
    public var description: String?
    public var deprecationReason: String?
    public var arguments: [ArgumentConfiguration]
    #warning("TODO: Think about how to improve this ergonomics. Maybe hide the original in a wrapper to be able to unwrap it?")
    public var resolve: GraphQLFieldResolve
}

extension FieldConfiguration {
    init(_ pair: (String, GraphQLFieldDefinition)) {
        let (name, fieldDefinition) = pair
        self.name = name
        self.description = fieldDefinition.description
        self.deprecationReason = fieldDefinition.deprecationReason
        self.arguments = fieldDefinition.args.map(ArgumentConfiguration.init)
        // We're guarateed to have resolve because the Graphiti.Field implementation always
        // provides a resolve function
        self.resolve = fieldDefinition.resolve!
    }
}

public struct ConfigureFieldDefinition {
    let configure: (inout FieldConfiguration) -> Void
    
    init(configure: @escaping (inout FieldConfiguration) -> Void) {
        self.configure = configure
    }
}

public protocol FieldDefinitionDirective {
    var fieldDefinition: ConfigureFieldDefinition { get }
}
