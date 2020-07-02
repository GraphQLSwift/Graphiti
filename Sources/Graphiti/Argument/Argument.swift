import GraphQL

public class Argument<ArgumentsType : Decodable, ArgumentType> : ArgumentComponent<ArgumentsType> {
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
        _ name: String,
        at keyPath: KeyPath<ArgumentsType, ArgumentType>
    ) {
        self.init(name:name)
    }
}

public extension Argument where ArgumentType : Encodable {
    func defaultValue(_ defaultValue: ArgumentType) -> Self {
        self.defaultValue = AnyEncodable(defaultValue)
        return self
    }
}
