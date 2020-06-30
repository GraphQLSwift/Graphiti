public class Component<RootType : Keyable, Context> {
    let name: String
    var description: String? = nil
    
    init(name: String) {
        self.name = name
    }
    
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    func update(builder: SchemaBuilder) throws {}
}
