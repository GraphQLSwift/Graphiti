import GraphQL

public final class ConnectionType<Resolver, Context, ObjectType : Encodable> : Component<Resolver, Context> {
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

        let edge = Type<Resolver, Context, Edge<ObjectType>>(Edge<ObjectType>.self) {
            Field("node", at: \.node)
            Field("cursor", at: \.cursor)
        }
        
        try edge.update(typeProvider: typeProvider, coders: coders)

        let connection = Type<Resolver, Context, Connection<ObjectType>>(Connection<ObjectType>.self) {
            Field("edges", at: \.edges)
            Field("pageInfo", at: \.pageInfo)
        }
        
        try connection.update(typeProvider: typeProvider, coders: coders)
    }
    
    private init(type: ObjectType.Type) {
        super.init(name: "")
    }
    
    public required init(extendedGraphemeClusterLiteral string: String) {
        fatalError("init(extendedGraphemeClusterLiteral:) has not been implemented")
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        fatalError("init(stringLiteral:) has not been implemented")
    }
    
    public required init(unicodeScalarLiteral string: String) {
        fatalError("init(unicodeScalarLiteral:) has not been implemented")
    }
}

public extension ConnectionType {
    convenience init(_ type: ObjectType.Type) {
        self.init(type: type)
    }
}
