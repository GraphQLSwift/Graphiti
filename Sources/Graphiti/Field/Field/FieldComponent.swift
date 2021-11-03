import GraphQL

public class FieldComponent<ObjectType, Context>: ExpressibleByStringLiteral {
    var description: String? = nil
    var deprecationReason: String? = nil
    
    func field(typeProvider: SchemaTypeProvider, coders: Coders) throws -> (String, GraphQLField) {
        fatalError()
    }
    
    init() {}
    
    public required init(unicodeScalarLiteral string: String) {
        self.description = string
    }
    
    public required init(extendedGraphemeClusterLiteral string: String) {
        self.description = string
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        self.description = string
    }
}

public extension FieldComponent {
    @available(*, deprecated, message: "Use a string literal above a component to give it a description.")
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    @available(*, deprecated, message: "Use deprecated(reason:).")
    func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
    
    func deprecated(reason deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
