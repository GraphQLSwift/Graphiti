/// A builder that allows modular creation of schema subscription operations.
public final class SubscriptionBuilder<Resolver, Context> {
    /// The name of the subscription type in the GraphQL schema
    public var name: String
    var fields: [FieldComponent<Resolver, Context>]

    public init(
        resolverType _: Resolver.Type,
        contextType _: Context.Type
    ) {
        name = "Subscription"
        fields = []
    }

    @discardableResult
    /// Adds multiple subscription operation definitions to the schema.
    /// - Parameter component: The mutation operations to add
    /// - Returns: This object for method chaining
    public func add(
        @FieldComponentBuilder<Resolver, Context> _ fields: () -> [FieldComponent<Resolver, Context>]
    ) -> Self {
        for field in fields() {
            self.fields.append(field)
        }
        return self
    }

    func build() -> Subscription<Resolver, Context> {
        return Subscription(name: name, fields: fields)
    }
}
