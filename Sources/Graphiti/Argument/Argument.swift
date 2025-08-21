import GraphQL

public class Argument<ArgumentsType: Decodable, ArgumentType>: ArgumentComponent<ArgumentsType> {
    let name: String
    var defaultValue: AnyEncodable?

    override func argument(
        typeProvider: TypeProvider,
        coders: Coders
    ) throws -> (String, GraphQLArgument) {
        let argument = try GraphQLArgument(
            type: typeProvider.getInputType(from: ArgumentType.self, field: name),
            description: description,
            defaultValue: defaultValue.map { try coders.encoder.encode($0) }
        )

        return (name, argument)
    }

    override func getName() -> String {
        return name
    }

    init(name: String) {
        self.name = name
    }
}

public extension Argument {
    convenience init(
        _ name: String,
        at _: KeyPath<ArgumentsType, ArgumentType>
    ) {
        self.init(name: name)
    }
}

public extension Argument where ArgumentType: Encodable {
    func defaultValue(_ defaultValue: ArgumentType) -> Self {
        self.defaultValue = AnyEncodable(defaultValue)
        return self
    }
}
