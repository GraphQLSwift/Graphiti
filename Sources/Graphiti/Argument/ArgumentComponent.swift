import GraphQL

public class ArgumentComponent<ArgumentsType: Decodable> {
    var description: String?

    func argument(
        typeProvider _: TypeProvider,
        coders _: Coders
    ) throws -> (String, GraphQLArgument) {
        fatalError()
    }

    func getName() -> String {
        fatalError()
    }
}

public extension ArgumentComponent {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
