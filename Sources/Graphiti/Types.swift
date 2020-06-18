public final class Types<Root : Keyable, Context> : Component<Root, Context> {
    let types: [Any.Type]
    
    override func update(builder: SchemaBuilder) throws {
        builder.types = try types.map {
            try builder.getNamedType(from: $0)
        }
    }
    
    init(_ types: [Any.Type]) {
        self.types = types
    }
}
