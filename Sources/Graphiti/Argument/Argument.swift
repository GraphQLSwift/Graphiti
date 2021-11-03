import GraphQL

public class Argument<ArgumentsType : Decodable, ArgumentType> : ArgumentComponent<ArgumentsType> {
    let name: String
    var defaultValue: AnyEncodable? = nil
    
    override func argument(typeProvider: TypeProvider, coders: Coders) throws -> (String, GraphQLArgument) {
        let argument = GraphQLArgument(
            type: try typeProvider.getInputType(from: ArgumentType.self, field: name),
            description: description,
            defaultValue: try defaultValue.map({ try coders.encoder.encode($0) })
        )
        
        return (name, argument)
    }
    
    init(name: String) {
        self.name = name
        super.init()
    }

    public required init(stringLiteral string: StringLiteralType) {
        fatalError("init(stringLiteral:) has not been implemented")
    }
}

public extension Argument {
    @available(*, deprecated, message: "Use Argument.init(_:of:at:) instead.")
    convenience init(
        _ name: String,
        at keyPath: KeyPath<ArgumentsType, ArgumentType>
    ) {
        self.init(name:name)
    }
    
    convenience init(
        _ name: String,
        of type: ArgumentType.Type,
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
