import GraphQL

public class FieldComponent<ObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
    var description: String? = nil
    var deprecationReason: String? = nil
    
    func field(provider: TypeProvider) throws -> (String, GraphQLField) {
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
