import GraphQL

@Sendable
public func NoIntrospectionRule(context: ValidationContext) -> Visitor {
    return Visitor(enter: { node, _, _, _, _ in
        if let field = node as? GraphQL.Field, ["__schema", "__type"].contains(field.name.value) {
            context.report(error: .init(
                message: "GraphQL introspection is not allowed, but the query contained __schema or __type",
                nodes: [node]
            ))
        }
        return .continue
    })
}
