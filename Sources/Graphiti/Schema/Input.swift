import GraphQL

public class InputObjectTypeComponent<InputObjectType, FieldKey : RawRepresentable, Context> where FieldKey.RawValue == String {
    
    func field(provider: TypeProvider) throws -> (String, InputObjectField) {
        fatalError()
    }
    
    func fields(provider: TypeProvider) throws -> InputObjectConfigFieldMap {
        fatalError()
    }
}

private class MergerInputObjectTypeComponent<InputObjectType, FieldKey : RawRepresentable, Context> : InputObjectTypeComponent<InputObjectType, FieldKey, Context> where FieldKey.RawValue == String {
    let components: [InputObjectTypeComponent<InputObjectType, FieldKey, Context>]
    
    init(components: [InputObjectTypeComponent<InputObjectType, FieldKey, Context>]) {
        self.components = components
    }
    
    override func fields(provider: TypeProvider) throws -> InputObjectConfigFieldMap {
        var map: InputObjectConfigFieldMap = [:]
        
        for component in self.components {
            let (name, field) = try component.field(provider: provider)
            map[name] = field
        }
        
        return map
    }
}

@_functionBuilder
public struct InputObjectTypeBuilder<InputObjectType, FieldKey : RawRepresentable, Context> where FieldKey.RawValue == String {
    public static func buildBlock(_ components: InputObjectTypeComponent<InputObjectType, FieldKey, Context>...) -> InputObjectTypeComponent<InputObjectType, FieldKey, Context> {
        return MergerInputObjectTypeComponent(components: components)
    }
}

public final class Input<RootType : FieldKeyProvider, Context, InputObjectType : Decodable & FieldKeyProvider> : SchemaComponent<RootType, Context> {
    let name: String?
    let component: InputObjectTypeComponent<InputObjectType, InputObjectType.FieldKey, Context>
    
    override func update(schema: SchemaThingy) {
        let inputObjectType = try! GraphQLInputObjectType(
            name: self.name ?? fixName(String(describing: InputObjectType.self)),
            description: self.description,
            fields: self.component.fields(provider: schema)
        )
        
        try! schema.map(InputObjectType.self, to: inputObjectType)
    }
    
    public init(
        _ type: InputObjectType.Type,
        name: String? = nil,
        @InputObjectTypeBuilder<InputObjectType, InputObjectType.FieldKey, Context> component: () -> InputObjectTypeComponent<InputObjectType, InputObjectType.FieldKey, Context>
    ) {
        self.name = name
        self.component = component()
    }
}
