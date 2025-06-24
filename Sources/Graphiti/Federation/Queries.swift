import GraphQL

func serviceQuery(for sdl: String) -> GraphQLField {
    return GraphQLField(
        type: GraphQLNonNull(serviceType),
        description: "Return the SDL string for the subschema",
        resolve: { _, _, _, _ in
            let result = Service(sdl: sdl)
            return result
        }
    )
}

func entitiesQuery(
    for federatedResolvers: [String: GraphQLFieldResolve],
    entityType: GraphQLUnionType,
    coders: Coders
) -> GraphQLField {
    return GraphQLField(
        type: GraphQLNonNull(GraphQLList(entityType)),
        description: "Return all entities matching the provided representations.",
        args: [
            "representations": GraphQLArgument(type: GraphQLNonNull(GraphQLList(GraphQLNonNull(anyType)))),
        ],
        resolve: { source, args, context, info in
            let arguments = try coders.decoder.decode(EntityArguments.self, from: args)
            return try await withThrowingTaskGroup(of: (Int, Any?).self) { group in
                var results: [Any?] = arguments.representations.map { _ in nil }
                for (index, representationMap) in arguments.representations.enumerated() {
                    group.addTask {
                        let representation = try coders.decoder.decode(
                            EntityRepresentation.self,
                            from: representationMap
                        )
                        guard let resolve = federatedResolvers[representation.__typename] else {
                            throw GraphQLError(
                                message: "Federated type not found: \(representation.__typename)"
                            )
                        }
                        let result = try await resolve(
                            source,
                            representationMap,
                            context,
                            info
                        )
                        return (index, result)
                    }
                }
                for try await result in group {
                    results[result.0] = result.1
                }
                return results
            }
        }
    )
}
