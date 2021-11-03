import GraphQL

public class InputFieldComponent<InputObjectType, Context> {
    var description: String? = nil
    
    func field(typeProvider: TypeProvider) throws -> (String, InputObjectField) {
        fatalError()
    }
}

public extension InputFieldComponent {
    @available(*, deprecated, message: "Use a string literal above a component to give it a description.")
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}
