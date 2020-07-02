import GraphQL

public class ArgumentComponent<ArgumentsType : Decodable & Keyable> {
    var description: String? = nil
    
    func argument(provider: TypeProvider) throws -> (String, GraphQLArgument) {
        fatalError()
    }
}

public extension ArgumentComponent {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
