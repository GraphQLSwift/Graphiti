import GraphQL

open class Component<Resolver, Context> {
    let name: String
    var description: String?

    init(name: String) {
        self.name = name
    }

    func update(typeProvider _: SchemaTypeProvider, coders _: Coders) throws {}
}

public extension Component {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
