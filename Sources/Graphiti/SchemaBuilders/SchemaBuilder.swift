/// A builder that allows modular creation of GraphQL schemas. You may independently components or query, mutation, or subscription fields.
/// When ready to build and use the schema, run `build`
public final class SchemaBuilder<Resolver, Context> {
    private var coders: Coders
    private var typeComponents: [TypeComponent<Resolver, Context>]

    /// Defines the schema query operations
    public let query: QueryBuilder<Resolver, Context>
    /// Defines the schema mutation operations
    public let mutation: MutationBuilder<Resolver, Context>
    /// Defines the schema subscription operations
    public let subscription: SubscriptionBuilder<Resolver, Context>

    public init(
        _ resolverType: Resolver.Type,
        _ contextType: Context.Type
    ) {
        coders = Coders()
        typeComponents = []
        query = QueryBuilder(resolverType: resolverType, contextType: contextType)
        mutation = MutationBuilder(resolverType: resolverType, contextType: contextType)
        subscription = SubscriptionBuilder(resolverType: resolverType, contextType: contextType)
    }

    @discardableResult
    /// Allows for setting API encoders and decoders with customized settings.
    /// - Parameter newCoders: The new coders to use
    /// - Returns: This object for method chaining
    public func setCoders(to newCoders: Coders) -> Self {
        coders = newCoders
        return self
    }

    @discardableResult
    /// Adds multiple query operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func add(
        @TypeComponentBuilder<Resolver, Context> _ components: () -> [TypeComponent<Resolver, Context>]
    ) -> Self {
        for component in components() {
            typeComponents.append(component)
        }
        return self
    }

    /// Create and return the queryable GraphQL schema
    public func build() throws -> Schema<Resolver, Context> {
        var components = typeComponents.map { topLevelComponent in
            topLevelComponent as Component<Resolver, Context>
        }

        if !query.fields.isEmpty {
            components.append(query.build())
        }

        if !mutation.fields.isEmpty {
            components.append(mutation.build())
        }

        if !subscription.fields.isEmpty {
            components.append(subscription.build())
        }

        return try Schema(coders: coders, components: components)
    }
}
