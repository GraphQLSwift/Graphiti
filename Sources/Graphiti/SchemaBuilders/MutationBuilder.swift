/// A builder that allows modular creation of schema mutation operations.
public final class MutationBuilder<Resolver, Context> {
    /// The name of the mutation type in the GraphQL schema
    public var name: String
    var fields: [FieldComponent<Resolver, Context>]

    public init(
        resolverType _: Resolver.Type,
        contextType _: Context.Type
    ) {
        name = "Mutation"
        fields = []
    }

    @discardableResult
    /// Adds a mutation operation definition to the schema.
    /// - Parameter component: The mutation operation to add
    /// - Returns: This object for method chaining
    public func add(_ field: FieldComponent<Resolver, Context>) -> Self {
        fields.append(field)
        return self
    }

    @discardableResult
    /// Adds multiple mutation operation definitions to the schema.
    /// - Parameter component: The mutation operations to add
    /// - Returns: This object for method chaining
    public func add<T: Sequence>(
        _ fields: T
    ) -> Self where T.Element: FieldComponent<Resolver, Context> {
        for field in fields {
            self.fields.append(field)
        }
        return self
    }

    func build() -> Mutation<Resolver, Context> {
        return Mutation(name: name, fields: fields)
    }
}
