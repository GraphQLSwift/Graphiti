import GraphQL

public class InputField<InputObjectType, FieldKey : RawRepresentable, Context, FieldType : Encodable> : InputObjectTypeComponent<InputObjectType, FieldKey, Context>, Descriptable where FieldKey.RawValue == String {
    let name: String
    let defaultValue: Map?
    var description: String? = nil
    
    override func fields(provider: TypeProvider) throws -> InputObjectConfigFieldMap {
        let (name, field) = try self.field(provider: provider)
        return [name: field]
    }
    
    override func field(provider: TypeProvider) throws -> (String, InputObjectField) {
        let field = InputObjectField(
            type: try provider.getInputType(from: FieldType.self, field: self.name),
            defaultValue: self.defaultValue,
            description: self.description
        )
        
        return (self.name, field)
    }
    
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    public init(
        _ name: FieldKey,
        at keyPath: KeyPath<InputObjectType, FieldType>,
        defaultValue: FieldType? = nil
    ) {
        self.name = name.rawValue
        self.defaultValue = defaultValue.map({ try! MapEncoder().encode($0) })
    }
}
