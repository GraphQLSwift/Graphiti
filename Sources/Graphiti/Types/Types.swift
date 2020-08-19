public final class Types<Root, Context> : Component<Root, Context> {
    let types: [Any.Type]
    
    override func update(typeProvider: SchemaTypeProvider) throws {
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
