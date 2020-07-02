public final class ConnectionType<Root : Keyable, Context, ObjectType : Encodable & Keyable> : Component<Root, Context> {    
    override func update(builder: SchemaBuilder) throws {
        if !builder.contains(type: PageInfo.self) {
            let pageInfo = Type<Root, Context, PageInfo>(PageInfo.self,
                Field(\.hasPreviousPage, as: .hasPreviousPage),
                Field(\.hasNextPage, as: .hasNextPage),
                Field(\.startCursor, as: .startCursor),
                Field(\.endCursor, as: .endCursor)
            )
        
            try pageInfo.update(builder: builder)
        }

        let edge = Type<Root, Context, Edge<ObjectType>>(Edge<ObjectType>.self,
            Field(\.node, as: .node),
            Field(\.cursor, as: .cursor)
        )
        
        try edge.update(builder: builder)

        let connection = Type<Root, Context, Connection<ObjectType>>(Connection<ObjectType>.self,
            Field(\.edges, as: .edges),
            Field(\.pageInfo, as: .pageInfo)
        )
        
        try connection.update(builder: builder)
    }
    
    init(type: ObjectType.Type) {
        super.init(name: "")
    }
}

public extension ConnectionType {
    convenience init(_ type: ObjectType.Type) {
        self.init(type: type)
    }
}
