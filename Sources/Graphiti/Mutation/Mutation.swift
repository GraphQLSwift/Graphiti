import GraphQL

public final class Mutation<Resolver, Context> : Component<Resolver, Context> {
    let fields: [FieldComponent<Resolver, Context>]
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is Resolver
    }
    
    override func update(typeProvider: SchemaTypeProvider) throws {
        typeProvider.mutation = try GraphQLObjectType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider),
            isTypeOf: isTypeOf
        )
    }
    
    func fields(typeProvider: TypeProvider) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider)
            map[name] = field
        }
        
        return map
    }
    
    public init(
        name: String,
        fields: [FieldComponent<Resolver, Context>]
    ) {
        self.fields = fields
        super.init(name: name)
    }
}

public extension Mutation {
    convenience init(
        as name: String = "Mutation",
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> FieldComponent<Resolver, Context>
    ) {
        self.init(name: name, fields: [fields()])
    }
    
    convenience init(
        as name: String = "Mutation",
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> [FieldComponent<Resolver, Context>]
    ) {
        self.init(name: name, fields: fields())
    }
}
