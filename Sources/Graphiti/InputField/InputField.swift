import GraphQL

public class InputField<
    InputObjectType,
    Context: Sendable,
    FieldType
>: InputFieldComponent<InputObjectType, Context> {
    let name: String
    var defaultValue: AnyEncodable?

    override func field(typeProvider: TypeProvider) throws -> (String, InputObjectField) {
        let field = try InputObjectField(
            type: typeProvider.getInputType(from: FieldType.self, field: name),
            defaultValue: defaultValue.map {
                try MapEncoder().encode($0)
            },
            description: description
        )

        return (name, field)
    }

    init(
        name: String
    ) {
        self.name = name
    }
}

extension InputField {
    public convenience init(
        _ name: String,
        at _: KeyPath<InputObjectType, FieldType>
    ) {
        self.init(name: name)
    }
}

extension InputField where FieldType: Encodable {
    public func defaultValue(_ defaultValue: FieldType) -> Self {
        self.defaultValue = AnyEncodable(defaultValue)
        return self
    }
}
