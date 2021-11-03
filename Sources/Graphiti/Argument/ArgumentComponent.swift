import GraphQL

public class ArgumentComponent<ArgumentsType : Decodable>: ExpressibleByStringLiteral {
    var description: String? = nil
    
    init() {}
    
    func argument(typeProvider: TypeProvider, coders: Coders) throws -> (String, GraphQLArgument) {
        fatalError()
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        self.description = string
    }
}

public extension ArgumentComponent {
    @available(*, deprecated, message: "Use a string literal above a component to give it a description.")
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
