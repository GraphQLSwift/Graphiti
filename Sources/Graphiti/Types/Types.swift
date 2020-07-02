public final class Types<Root, Context> : Component<Root, Context> {
    let types: [Any.Type]
    
    override func update(builder: SchemaBuilder) throws {
        builder.types = try types.map {
            try builder.getNamedType(from: $0)
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
