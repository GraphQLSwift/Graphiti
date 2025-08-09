import GraphQL

public final class Query<Resolver: Sendable, Context: Sendable>: Component<Resolver, Context> {
    let fields: [FieldComponent<Resolver, Context>]

    let isTypeOf: GraphQLIsTypeOf = { source, _ in
        source is Resolver
    }

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        typeProvider.query = try GraphQLObjectType(
            name: name,
            description: description,
            fields: {
                var queryFields = try self.fields(typeProvider: typeProvider, coders: coders)

                // Add federated types and queries if they exist
                if !typeProvider.federatedTypes.isEmpty {
                    let federatedTypes = typeProvider.federatedTypes
                    guard let sdl = typeProvider.federatedSDL else {
                        throw GraphQLError(
                            message: "If federated types are included, SDL must be provided"
                        )
                    }

                    // Add subgraph types to provider (_Service, _Any, _Entity)
                    let entity = entityType(federatedTypes)
                    typeProvider.types.append(serviceType)
                    typeProvider.types.append(anyType)
                    typeProvider.types.append(entity)

                    // Add subgraph queries (_entities, _service)
                    queryFields["_entities"] = entitiesQuery(
                        for: typeProvider.federatedResolvers,
                        entityType: entity,
                        coders: coders
                    )
                    queryFields["_service"] = serviceQuery(for: sdl)
                }
                return queryFields
            },
            isTypeOf: isTypeOf
        )
    }

    func fields(typeProvider: TypeProvider, coders: Coders) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]

        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider, coders: coders)
            map[name] = field
        }

        return map
    }

    init(
        name: String,
        fields: [FieldComponent<Resolver, Context>]
    ) {
        self.fields = fields
        super.init(
            name: name,
            type: .query
        )
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
        @FieldComponentBuilder<Resolver, Context> _ fields: ()
            -> [FieldComponent<Resolver, Context>]
    ) {
        self.init(name: name, fields: fields())
    }
}
