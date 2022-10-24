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
    /// Adds a query operation definition to the schema.
    /// - Parameter component: The query operation to add
    /// - Returns: This object for method chaining
    public func add(_ field: FieldComponent<Resolver, Context>) -> Self {
        fields.append(field)
        return self
    }

    @discardableResult
    /// Adds multiple query operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func add<T: Sequence>(
        _ fields: T
    ) -> Self where T.Element: FieldComponent<Resolver, Context> {
        for field in fields {
            self.fields.append(field)
        }
        return self
    }

    func build() -> Query<Resolver, Context> {
        return Query(name: name, fields: fields)
    }
}
