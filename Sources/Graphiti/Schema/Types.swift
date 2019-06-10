public final class Types<Root : FieldKeyProvider, Context> : SchemaComponent<Root, Context> {
    let types: [Any.Type]
    
    override func update(schema: SchemaThingy) {
        schema.types = self.types.map {
            try! schema.getNamedType(from: $0)
        }
    }
    
    public init(_ types: Any.Type...) {
        self.types = types
    }
}
