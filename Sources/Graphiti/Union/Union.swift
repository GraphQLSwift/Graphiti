import GraphQL

public final class Union<
    Resolver: Sendable,
    Context: Sendable,
    UnionType
>: TypeComponent<
    Resolver,
    Context
> {
    private let members: [Any.Type]

    override func update(typeProvider: SchemaTypeProvider, coders _: Coders) throws {
        let unionType = try GraphQLUnionType(
            name: name,
            description: description,
            resolveType: nil,
            types: {
                try self.members.map {
                    try typeProvider.getObjectType(from: $0)
                }
            }
        )

        try typeProvider.add(type: UnionType.self, as: unionType)
    }

    init(
        type _: UnionType.Type,
        name: String? = nil,
        members: [Any.Type]
    ) {
        self.members = members
        super.init(
            name: name ?? Reflection.name(for: UnionType.self),
            type: .union
        )
    }
}

public extension Union {
    convenience init(
        _ type: UnionType.Type,
        as name: String? = nil,
        members: Any.Type...
    ) {
        self.init(type: type, name: name, members: members)
    }

    convenience init(
        _ type: UnionType.Type,
        as name: String? = nil,
        members: [Any.Type]
    ) {
        self.init(type: type, name: name, members: members)
    }
}
