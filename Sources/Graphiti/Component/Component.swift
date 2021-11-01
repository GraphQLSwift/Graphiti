import GraphQL

open class Component<Resolver, Context>: ExpressibleByStringLiteral {
    let name: String
    var description: String? = nil
    
    init(name: String) {
        self.name = name
    }
    
    public required init(unicodeScalarLiteral string: String) {
        self.name = ""
        self.description = string
    }
    
    public required init(extendedGraphemeClusterLiteral string: String) {
        self.name = ""
        self.description = string
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        self.name = ""
        self.description = string
    }
    
    func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {}
}

public extension Component {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
