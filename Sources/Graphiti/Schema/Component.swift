open class Component<RootType, Context> {
    let name: String
    var description: String? = nil
    
    init(name: String) {
        self.name = name
    }
    
    
    func update(builder: SchemaBuilder) throws {}
}

public extension Component {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
