import GraphQL

public final class InputFieldInitializer<InputObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
    var field: InputFieldComponent<InputObjectType, Keys, Context>
    
    init(_ field: InputFieldComponent<InputObjectType, Keys, Context>) {
        self.field = field
    }
    
    @discardableResult
    public func description(_ description: String) -> Self {
        field.description = description
        return self
    }
}
