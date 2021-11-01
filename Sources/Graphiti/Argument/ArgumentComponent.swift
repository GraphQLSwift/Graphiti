import GraphQL

public class ArgumentComponent<ArgumentsType : Decodable>: ExpressibleByStringLiteral {
    var description: String? = nil
    
    init() {}
    
    func argument(typeProvider: TypeProvider, coders: Coders) throws -> (String, GraphQLArgument) {
        fatalError()
    }
    
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

public extension ArgumentComponent {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
