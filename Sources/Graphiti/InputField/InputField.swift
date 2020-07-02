import GraphQL

public class InputField<InputObjectType, Keys : RawRepresentable, Context, FieldType> : InputFieldComponent<InputObjectType, Keys, Context> where Keys.RawValue == String {
    let name: String
    var defaultValue: AnyEncodable?
    
    override func field(provider: TypeProvider) throws -> (String, InputObjectField) {
        let field = InputObjectField(
            type: try provider.getInputType(from: FieldType.self, field: name),
            defaultValue: try defaultValue.map {
                try MapEncoder().encode($0)
            },
            description: description
        )
        
        return (self.name, field)
    }
    
    init(
        name: String
    ) {
        self.name = name
    }
}

public extension InputField {
    convenience init(
        _ keyPath: KeyPath<InputObjectType, FieldType>,
        as name: Keys
    ) {
        self.init(name: name.rawValue)
    }
}

public extension InputField where FieldType : Encodable {
    func defaultValue(_ defaultValue: FieldType) -> Self {
        self.defaultValue = AnyEncodable(defaultValue)
        return self
    }
}
