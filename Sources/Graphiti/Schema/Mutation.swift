import GraphQL

public final class Mutation<RootType : FieldKeyProvider, Context> : SchemaComponent<RootType, Context> {
    let name: String
    let component: ObjectTypeComponent<RootType, RootType.FieldKey, Context>
    
    override func update(schema: SchemaThingy) {
        schema.mutation = try! GraphQLObjectType(
            name: name,
            description: self.description,
            fields: component.fields(provider: schema),
            isTypeOf: component.isTypeOf
        )
    }
    
    public init(
        name: String = "Mutation",
        @ObjectTypeBuilder<RootType, RootType.FieldKey, Context> component: () -> ObjectTypeComponent<RootType, RootType.FieldKey, Context>
    ) {
        self.name = name
        self.component = component()
    }
}
