import GraphQL

public class ArgumentComponent<ArgumentsType : Decodable> {
    var description: String? = nil
    
    func argument(typeProvider: TypeProvider, coders: Coders) throws -> (String, GraphQLArgument) {
        fatalError()
    }
}

public extension ArgumentComponent {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
