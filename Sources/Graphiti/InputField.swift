import GraphQL

public class InputField<InputObjectType, Keys : RawRepresentable, Context, FieldType : Encodable> : InputFieldComponent<InputObjectType, Keys, Context> where Keys.RawValue == String {
    let name: String
    let defaultValue: AnyEncodable?
    
    override func fields(provider: TypeProvider) throws -> InputObjectConfigFieldMap {
        let (name, field) = try self.field(provider: provider)
        return [name: field]
    }
    
    override func field(provider: TypeProvider) throws -> (String, InputObjectField) {
        let field = InputObjectField(
            type: try provider.getInputType(from: FieldType.self, field: self.name),
            defaultValue: try defaultValue.map {
                try MapEncoder().encode($0)
            },
            description: description
        )
        
        return (self.name, field)
    }
    
    init(
        name: Keys,
        at keyPath: KeyPath<InputObjectType, FieldType>,
        defaultValue: FieldType?
    ) {
        self.name = name.rawValue
        self.defaultValue = defaultValue.map({ AnyEncodable($0) })
    }
}
