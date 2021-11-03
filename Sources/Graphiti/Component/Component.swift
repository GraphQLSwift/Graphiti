import GraphQL

open class Component<Resolver, Context>: ExpressibleByStringLiteral {
    let name: String
    var description: String? = nil
    
    init(name: String) {
        self.name = name
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        self.name = ""
        self.description = string
    }
    
    func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {}
}

public extension Component {
    @available(*, deprecated, message: "Use a string literal above a component to give it a description.")
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
