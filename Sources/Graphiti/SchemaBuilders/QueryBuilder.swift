/// A builder that allows modular creation of schema query operations.
public final class QueryBuilder<Resolver, Context> {
    /// The name of the query type in the GraphQL schema
    public var name: String
    var fields: [FieldComponent<Resolver, Context>]

    public init(
        resolverType _: Resolver.Type,
        contextType _: Context.Type
    ) {
        name = "Query"
        fields = []
    }
    
    @discardableResult
    /// Adds multiple query operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func add(
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> [FieldComponent<Resolver, Context>]
    ) -> Self {
        for field in fields() {
            self.fields.append(field)
        }
        return self
    }

    func build() -> Query<Resolver, Context> {
        return Query(name: name, fields: fields)
    }
}
