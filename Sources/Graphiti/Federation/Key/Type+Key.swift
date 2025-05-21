import GraphQL

public extension Type {
    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key value. The name of this argument must match a Type field.
    /// - Returns: Self for chaining.
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping AsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) -> Self {
        keys.append(Key(arguments: [argument()], asyncResolve: function))
        return self
    }

    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key values. The names of these arguments must match Type fields.
    /// - Returns: Self for chaining.
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping AsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) -> Self {
        keys.append(Key(arguments: arguments(), asyncResolve: function))
        return self
    }

    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key value. The name of this argument must match a Type field.
    /// - Returns: Self for chaining.
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping SimpleAsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) -> Self {
        keys.append(Key(arguments: [argument()], simpleAsyncResolve: function))
        return self
    }

    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key values. The names of these arguments must match Type fields.
    /// - Returns: Self for chaining.
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping SimpleAsyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) -> Self {
        keys.append(Key(arguments: arguments(), simpleAsyncResolve: function))
        return self
    }

    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key value. The name of this argument must match a Type field.
    /// - Returns: Self for chaining.
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping SyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) -> Self {
        keys.append(Key(arguments: arguments(), syncResolve: function))
        return self
    }

    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key values. The names of these arguments must match Type fields.
    /// - Returns: Self for chaining.
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping SyncResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) -> Self {
        keys.append(Key(arguments: [argument()], syncResolve: function))
        return self
    }
}

public extension Type {
    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key value. The name of this argument must match a Type field.
    /// - Returns: Self for chaining.
    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping ConcurrentResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) -> Self {
        keys.append(Key(arguments: [argument()], concurrentResolve: function))
        return self
    }

    /// Define and add the federated key to this type.
    ///
    /// For more information, see https://www.apollographql.com/docs/federation/entities
    /// - Parameters:
    ///   - function: The resolver function used to load this entity based on the key value.
    ///   - _:  The key values. The names of these arguments must match Type fields.
    /// - Returns: Self for chaining.
    @available(macOS 10.15, iOS 15, watchOS 8, tvOS 15, *)
    @discardableResult
    func key<Arguments: Codable>(
        at function: @escaping ConcurrentResolve<Resolver, Context, Arguments, ObjectType?>,
        @ArgumentComponentBuilder<Arguments> _ arguments: () -> [ArgumentComponent<Arguments>]
    ) -> Self {
        keys.append(Key(arguments: arguments(), concurrentResolve: function))
        return self
    }
}
