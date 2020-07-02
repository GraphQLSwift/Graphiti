import GraphQL

public class Argument<ArgumentsType : Decodable & Keyable, ArgumentType> : ArgumentComponent<ArgumentsType> {
    let name: String
    var defaultValue: AnyEncodable? = nil
    
    override func argument(provider: TypeProvider) throws -> (String, GraphQLArgument) {
        let argument = GraphQLArgument(
            type: try provider.getInputType(from: ArgumentType.self, field: name),
            description: description,
            defaultValue: try defaultValue.map({ try MapEncoder().encode($0) })
        )
        
        return (name, argument)
    }
    
    init(name: String) {
        self.name = name
    }
}

public extension Argument {
    convenience init(
        _ keyPath: KeyPath<ArgumentsType, ArgumentType>,
        as name: ArgumentsType.Keys
    ) {
        self.init(name:name.rawValue)
    }
}

public extension Argument where ArgumentType : Encodable {
    func defaultValue(_ defaultValue: ArgumentType) -> Self {
        self.defaultValue = AnyEncodable(defaultValue)
        return self
    }
}
