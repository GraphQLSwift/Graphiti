import GraphQL

public struct ArgumentConfiguration {
    public let name: String
    public var defaultValue: Map?
}

public struct FieldConfiguration {
    public let name: String
    public var description: String?
    public var deprecationReason: String?
    public var arguments: [ArgumentConfiguration]
    public var resolve: AsyncResolve<Any, Any, Any, Any?>
}

public protocol FieldDefinitionDirective {
    var fieldDefinition: (inout FieldConfiguration) -> Void { get }
}
