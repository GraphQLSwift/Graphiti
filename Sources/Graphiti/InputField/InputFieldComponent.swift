import GraphQL

public class InputFieldComponent<InputObjectType, Context> {
    var description: String?

    func field(typeProvider _: TypeProvider) throws -> (String, InputObjectField) {
        fatalError()
    }
}

extension InputFieldComponent {
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
