import GraphQL

public final class Query<RootType : FieldKeyProvider, Context> : SchemaComponent<RootType, Context> {
    let name: String
    let component: ObjectTypeComponent<RootType, RootType.FieldKey, Context>
    
    override func update(schema: SchemaThingy) {
        schema.query = try! GraphQLObjectType(
            name: name,
            description: self.description,
            fields: component.fields(provider: schema),
            isTypeOf: component.isTypeOf
        )
    }
    
    public init(
        name: String = "Query",
        @ObjectTypeBuilder<RootType, RootType.FieldKey, Context> component: () -> ObjectTypeComponent<RootType, RootType.FieldKey, Context>
    ) {
        self.name = name
        self.component = component()
    }
}
