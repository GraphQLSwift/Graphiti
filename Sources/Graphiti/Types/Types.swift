import GraphQL

public final class Types<Resolver, Context> : Component<Resolver, Context> {
    let types: [Any.Type]
    
    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        typeProvider.types = try types.map {
            try typeProvider.getNamedType(from: $0)
        }
    }
    
    init(types: [Any.Type]) {
        self.types = types
        super.init(name: "")
    }
}

public extension Types {
    convenience init(_ types: Any.Type...) {
        self.init(types: types)
    }
}
