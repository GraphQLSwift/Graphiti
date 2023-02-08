/// A builder that allows modular creation of GraphQL schemas. You may independently components or query, mutation, or subscription fields.
/// When ready to build and use the schema, run `build`
public final class SchemaBuilder<Resolver, Context> {
    private var coders: Coders
    private var typeComponents: [TypeComponent<Resolver, Context>]
    private var queryName: String
    private var queryFields: [FieldComponent<Resolver, Context>]
    private var mutationName: String
    private var mutationFields: [FieldComponent<Resolver, Context>]
    private var subscriptionName: String
    private var subscriptionFields: [FieldComponent<Resolver, Context>]

    public init(
        _: Resolver.Type,
        _: Context.Type
    ) {
        coders = Coders()
        typeComponents = []

        queryName = "Query"
        queryFields = []
        mutationName = "Mutation"
        mutationFields = []
        subscriptionName = "Subscription"
        subscriptionFields = []
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
    public func setQueryName(to name: String) -> Self {
        queryName = name
        return self
    }

    @discardableResult
    public func setMutationName(to name: String) -> Self {
        mutationName = name
        return self
    }

    @discardableResult
    public func setSubscriptionName(to name: String) -> Self {
        subscriptionName = name
        return self
    }

    @discardableResult
    /// Adds multiple query operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func add(
        @TypeComponentBuilder<Resolver, Context> _ components: ()
            -> [TypeComponent<Resolver, Context>]
    ) -> Self {
        for component in components() {
            typeComponents.append(component)
        }
        return self
    }

    @discardableResult
    /// Adds multiple query operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func addQuery(
        @FieldComponentBuilder<Resolver, Context> _ fields: ()
            -> [FieldComponent<Resolver, Context>]
    ) -> Self {
        for field in fields() {
            queryFields.append(field)
        }
        return self
    }

    @discardableResult
    /// Adds multiple mutation operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func addMutation(
        @FieldComponentBuilder<Resolver, Context> _ fields: ()
            -> [FieldComponent<Resolver, Context>]
    ) -> Self {
        for field in fields() {
            mutationFields.append(field)
        }
        return self
    }

    @discardableResult
    /// Adds multiple subscription operation definitions to the schema.
    /// - Parameter component: The query operations to add
    /// - Returns: This object for method chaining
    public func addSubscription(
        @FieldComponentBuilder<Resolver, Context> _ fields: ()
            -> [FieldComponent<Resolver, Context>]
    ) -> Self {
        for field in fields() {
            subscriptionFields.append(field)
        }
        return self
    }

    @discardableResult
    /// Adds multiple type, query, mutation, and subscription definitions using partial schemas to the schema.
    /// - Parameter partials: Partial schemas that declare types, query, mutation, and/or subscription definiton
    /// - Returns: Thie object for method chaining
    public func use(partials: [PartialSchema<Resolver, Context>]) -> Self {
        for type in partials.flatMap({ $0.types }) {
            typeComponents.append(type)
        }
        for query in partials.flatMap({ $0.query }) {
            queryFields.append(query)
        }
        for mutation in partials.flatMap({ $0.mutation }) {
            mutationFields.append(mutation)
        }
        for subscription in partials.flatMap({ $0.subscription }) {
            subscriptionFields.append(subscription)
        }
        return self
    }

    /// Create and return the queryable GraphQL schema
    public func build() throws -> Schema<Resolver, Context> {
        var components = typeComponents.map { topLevelComponent in
            topLevelComponent as Component<Resolver, Context>
        }

        if !queryFields.isEmpty {
            let query = Query(name: queryName, fields: queryFields)
            components.append(query)
        }

        if !mutationFields.isEmpty {
            let mutation = Mutation(name: mutationName, fields: mutationFields)
            components.append(mutation)
        }

        if !subscriptionFields.isEmpty {
            let subscription = Subscription(name: subscriptionName, fields: subscriptionFields)
            components.append(subscription)
        }

        return try Schema(coders: coders, components: components)
    }
}

extension SchemaBuilder where Resolver: FederationResolver, Resolver.Context == Context {
    @discardableResult
    /// Enable federation to add additional capabilities for federation subgraph support
    public func enableFederation() -> Self {
        use(partials: [FederationSchema(entityTypes: Resolver.entityKeys.map { $0.entity })])
        return self
    }
}
