import GraphQL

public class InputFieldComponent<InputObjectType, Context> {
    var description: String? = nil
    
    func field(provider: TypeProvider) throws -> (String, InputObjectField) {
        fatalError()
    }
}

public extension InputFieldComponent {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
