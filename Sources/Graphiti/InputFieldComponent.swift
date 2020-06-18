import GraphQL

public class InputFieldComponent<InputObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
    var description: String? = nil
    
    func field(provider: TypeProvider) throws -> (String, InputObjectField) {
        fatalError()
    }
    
    func fields(provider: TypeProvider) throws -> InputObjectConfigFieldMap {
        fatalError()
    }
}
