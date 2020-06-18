public final class InputFieldsInitializer<InputObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
    var fields: [InputFieldComponent<InputObjectType, Keys, Context>] = []

    @discardableResult
    public func field<FieldType : Encodable>(
        _ name: Keys,
        at keyPath: KeyPath<InputObjectType, FieldType>,
        defaultValue: FieldType? = nil
    ) -> InputFieldInitializer<InputObjectType, Keys, Context> {
        let field = InputField<InputObjectType, Keys, Context, FieldType>(
            name: name,
            at: keyPath,
            defaultValue: defaultValue
        )
        
        fields.append(field)
        return InputFieldInitializer(field)
    }
}
