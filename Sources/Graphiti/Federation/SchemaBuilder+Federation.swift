import GraphQL

extension SchemaBuilder where Resolver: FederationResolver, Resolver.Context == Context {
    @discardableResult
    /// Enable federation to add additional capabilities for federation subgraph support
    public func enableFederation() -> Self {
        let federationSchema = PartialSchema<Resolver, Context>(
        types: {
            Scalar(Map.self, as: "_Any")
            Union(FederationEntity.self, as: "_Entity", members: Resolver.entityKeys.map { $0.entity })
            Type(FederationServiceType.self, as: "_Service") {
                Field("sdl", at: \.sdl)
            }
        },
        query: {
            Field("_entities", at: Resolver.entityResolver, as: [FederationEntity?].self) {
                Argument("representations", at: \.representations)
            }
            Field("_service", at: Resolver.serviceResolver)
        })

        use(partials: [federationSchema])
        return self
    }
}
