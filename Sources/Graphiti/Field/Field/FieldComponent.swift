import GraphQL

public class FieldComponent<ObjectType, Context> {
    var description: String?
    var deprecationReason: String?

    func field(typeProvider _: TypeProvider, coders _: Coders) throws -> (String, GraphQLField) {
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
