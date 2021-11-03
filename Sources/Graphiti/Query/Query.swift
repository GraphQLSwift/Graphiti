import GraphQL

public final class Query<Resolver, Context> : Component<Resolver, Context> {
    let fields: [FieldComponent<Resolver, Context>]
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is Resolver
    }
    
    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        guard typeProvider.query == nil else {
            throw GraphQLError(
                message: "Duplicate Query type. There can only be a single Query type in a Schema."
            )
        }
        
        typeProvider.query = try GraphQLObjectType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider, coders: coders),
            isTypeOf: isTypeOf
        )
    }
    
    func fields(typeProvider: SchemaTypeProvider, coders: Coders) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider, coders: coders)
            map[name] = field
        }
        
        return map
    }
    
    private init(
        name: String,
        fields: [FieldComponent<Resolver, Context>]
    ) {
        self.fields = fields
        super.init(name: name)
    }
    
    public required init(extendedGraphemeClusterLiteral string: String) {
        fatalError("init(extendedGraphemeClusterLiteral:) has not been implemented")
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        fatalError("init(stringLiteral:) has not been implemented")
    }
    
    public required init(unicodeScalarLiteral string: String) {
        fatalError("init(unicodeScalarLiteral:) has not been implemented")
    }
}

public extension Query {
    convenience init(
        as name: String = "Query",
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> FieldComponent<Resolver, Context>
    ) {
        self.init(name: name, fields: [fields()])
    }
    
    convenience init(
        as name: String = "Query",
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> [FieldComponent<Resolver, Context>]
    ) {
        self.init(name: name, fields: fields())
    }
}
