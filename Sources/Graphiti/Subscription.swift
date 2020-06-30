import GraphQL

public final class Subscription<RootType : Keyable, Context> : Component<RootType, Context> {
    let fields: [FieldComponent<RootType, RootType.Keys, Context>]
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is RootType
    }
    
    override func update(builder: SchemaBuilder) throws {
        builder.subscription = try GraphQLObjectType(
            name: name,
            description: description,
            fields: fields(provider: builder),
            isTypeOf: isTypeOf
        )
    }
    
    func fields(provider: TypeProvider) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(provider: provider)
            map[name] = field
        }
        
        return map
    }
    
    init(
        name: String = "Subscription",
        fields: [FieldComponent<RootType, RootType.Keys, Context>]
    ) {
        self.fields = fields
        super.init(name: name)
    }
}
