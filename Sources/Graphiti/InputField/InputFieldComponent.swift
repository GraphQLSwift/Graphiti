import GraphQL

public class InputFieldComponent<InputObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
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
