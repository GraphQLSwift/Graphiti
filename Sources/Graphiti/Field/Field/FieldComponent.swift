import GraphQL

public class FieldComponent<ObjectType, Context> {
    var description: String? = nil
    var deprecationReason: String? = nil
    
    func field(typeProvider: TypeProvider) throws -> (String, GraphQLField) {
        fatalError()
    }
}

public extension FieldComponent {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
