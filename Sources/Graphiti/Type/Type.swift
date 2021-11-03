import GraphQL

public final class Type<Resolver, Context, ObjectType> : Component<Resolver, Context> where ObjectType: Encodable {
    let interfaces: [Any.Type]
    let fields: [FieldComponent<ObjectType, Context>]
    private var directives: [ObjectDirective] = []
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        source is ObjectType
    }
    
    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        applyDirectives()
        
        let objectType = try GraphQLObjectType(
            name: name,
            description: description,
            fields: try fields(typeProvider: typeProvider, coders: coders),
            interfaces: try interfaces.map {
                try typeProvider.getInterfaceType(from: $0)
            },
            isTypeOf: isTypeOf
        )
        
        try typeProvider.map(ObjectType.self, to: objectType)
    }
    
    func fields(typeProvider: SchemaTypeProvider, coders: Coders) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider, coders: coders)
            map[name] = field
        }
        
        return map
    }
    
    func applyDirectives() {
        for directive in directives {
            directive.object(object: self)
        }
    }
    
    private init(
        type: ObjectType.Type,
        name: String?,
        interfaces: [Any.Type],
        fields: [FieldComponent<ObjectType, Context>]
    ) {
        self.interfaces = interfaces
        self.fields = fields
        super.init(name: name ?? Reflection.name(for: ObjectType.self))
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

public extension Type {
    @available(*, deprecated, message: "Use the initializer where the label for the interfaces parameter is named `implements`.")
    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        interfaces: [Any.Type],
        @FieldComponentBuilder<ObjectType, Context> _ fields: () -> FieldComponent<ObjectType, Context>
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: [fields()]
        )
    }
    
    @available(*, deprecated, message: "Use the initializer where the label for the interfaces parameter is named `implements`.")
    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        interfaces: [Any.Type],
        @FieldComponentBuilder<ObjectType, Context> _ fields: () -> [FieldComponent<ObjectType, Context>]
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: fields()
        )
    }
}

public extension Type {
    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        implements interfaces: Any.Type...,
        @FieldComponentBuilder<ObjectType, Context> fields: () -> FieldComponent<ObjectType, Context>
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: [fields()]
        )
    }
    
    convenience init(
        _ type: ObjectType.Type,
        as name: String? = nil,
        implements interfaces: Any.Type...,
        @FieldComponentBuilder<ObjectType, Context> fields: () -> [FieldComponent<ObjectType, Context>]
    ) {
        self.init(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: fields()
        )
    }
}

// MARK: Directive

extension Type {
    func directive<Directive>(_ directive: Directive) -> Type where Directive: ObjectDirective {
        directives.append(directive)
        return self
    }
}
