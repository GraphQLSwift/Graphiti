import GraphQL

open class Component<Resolver, Context> {
    let name: String
    var description: String? = nil
    
    init(name: String) {
        self.name = name
    }
    
    
    func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {}
}

public extension Component {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
