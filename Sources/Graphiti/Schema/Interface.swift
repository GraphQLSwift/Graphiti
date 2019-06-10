import GraphQL

public final class Interface<RootType : FieldKeyProvider, Context, InterfaceType, FieldKey : RawRepresentable> : SchemaComponent<RootType, Context> where FieldKey.RawValue == String {
    let name: String?
    let component: ObjectTypeComponent<InterfaceType, FieldKey, Context>
    
    override func update(schema: SchemaThingy) {
        let interfaceType = try! GraphQLInterfaceType(
            name: self.name ?? fixName(String(describing: InterfaceType.self)),
            description: self.description,
            fields: self.component.fields(provider: schema),
            resolveType: nil
        )
        
        try! schema.map(InterfaceType.self, to: interfaceType)
    }
    
    public init(
        _ type: InterfaceType.Type,
        fieldKeys: FieldKey.Type,
        name: String? = nil,
        @ObjectTypeBuilder<InterfaceType, FieldKey, Context> component: () -> ObjectTypeComponent<InterfaceType, FieldKey, Context>
    )  {
        self.name = name
        self.component = component()
    }
}
