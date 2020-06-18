public class Component<RootType : Keyable, Context> {
    var description: String? = nil
    
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    func update(builder: SchemaBuilder) throws {}
}
