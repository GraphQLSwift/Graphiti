import GraphQL

public final class ConnectionType<
    Resolver,
    Context,
    ObjectType: Encodable
>: TypeComponent<
    Resolver,
    Context
> {
    let connectionFields: [FieldComponent<Connection<ObjectType>, Context>]
    let edgeFields: [FieldComponent<Edge<ObjectType>, Context>]

    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        if !typeProvider.contains(type: PageInfo.self) {
            let pageInfo = Type<Resolver, Context, PageInfo>(PageInfo.self) {
                Field("hasPreviousPage", at: \.hasPreviousPage)
                Field("hasNextPage", at: \.hasNextPage)
                Field("startCursor", at: \.startCursor)
                Field("endCursor", at: \.endCursor)
            }

            try pageInfo.update(typeProvider: typeProvider, coders: coders)
        }

        let edge = Type<Resolver, Context, Edge<ObjectType>>(
            Edge<ObjectType>.self,
            as: name + "Edge",
            fields: edgeFields + [
                Field("node", at: \.node),
                Field("cursor", at: \.cursor),
            ]
        )

        try edge.update(typeProvider: typeProvider, coders: coders)

        let connection = Type<Resolver, Context, Connection<ObjectType>>(
            Connection<ObjectType>.self,
            as: name + "Connection",
            fields: connectionFields + [
                Field("edges", at: \.edges),
                Field("pageInfo", at: \.pageInfo),
            ]
        )

        try connection.update(typeProvider: typeProvider, coders: coders)
    }

    private init(
        type _: ObjectType.Type,
        name: String?,
        connectionFields: [FieldComponent<Connection<ObjectType>, Context>],
        edgeFields: [FieldComponent<Edge<ObjectType>, Context>]
    ) {
        self.connectionFields = connectionFields
        self.edgeFields = edgeFields
        super.init(
            name: name ?? Reflection.name(for: ObjectType.self),
            type: .connection
        )
    }
}

public extension ConnectionType {
    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil
    ) {
        self.init(type: type, name: name, connectionFields: [], edgeFields: [])
    }

    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        @FieldComponentBuilder<Connection<ObjectType>, Context> connectionFields: ()
            -> FieldComponent<Connection<ObjectType>, Context>,
        @FieldComponentBuilder<Edge<ObjectType>, Context> edgeFields: ()
            -> FieldComponent<Edge<ObjectType>, Context>
    ) {
        self.init(
            type: type,
            name: name,
            connectionFields: [connectionFields()],
            edgeFields: [edgeFields()]
        )
    }

    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        @FieldComponentBuilder<Connection<ObjectType>, Context> connectionFields: ()
            -> [FieldComponent<Connection<ObjectType>, Context>] = { [] },
        @FieldComponentBuilder<Edge<ObjectType>, Context> edgeFields: ()
            -> [FieldComponent<Edge<ObjectType>, Context>] = { [] }
    ) {
        self.init(
            type: type,
            name: name,
            connectionFields: connectionFields(),
            edgeFields: edgeFields()
        )
    }
}
