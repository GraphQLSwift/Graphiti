import GraphQL

public final class Interface<Resolver, Context, InterfaceType> : Component<Resolver, Context> {
    let fields: [FieldComponent<InterfaceType, Context>]
    private var directives: [InterfaceDirective] = []
    
    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        applyDirectives()
        
        let interfaceType = try GraphQLInterfaceType(
            name: name,
            description: description,
            fields: fields(typeProvider: typeProvider, coders: coders),
            resolveType: nil
        )

        try typeProvider.map(InterfaceType.self, to: interfaceType)
    }
    
    func applyDirectives() {
        for directive in directives {
            directive.interface(interface: self)
        }
    }
    
    func fields(typeProvider: SchemaTypeProvider, coders: Coders) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for field in fields {
            let (name, field) = try field.field(typeProvider: typeProvider, coders: coders)
            map[name] = field
        }
        
        return map
    }
    
    private init(
        type: InterfaceType.Type,
        name: String? = nil,
        fields: [FieldComponent<InterfaceType, Context>]
    )  {
        self.fields = fields
        super.init(name: name ?? Reflection.name(for: InterfaceType.self))
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

public extension Interface {
    convenience init(
        _ type: InterfaceType.Type,
        as name: String? = nil,
        @FieldComponentBuilder<InterfaceType, Context> _ fields: () -> FieldComponent<InterfaceType, Context>
    ) {
        self.init(
            type: type,
            name: name,
            fields: [fields()]
        )
    }
    
    convenience init(
        _ type: InterfaceType.Type,
        as name: String? = nil,
        @FieldComponentBuilder<InterfaceType, Context> _ fields: () -> [FieldComponent<InterfaceType, Context>]
    ) {
        self.init(
            type: type,
            name: name,
            fields: fields()
        )
    }
}

// MARK: Directive

extension Interface {
    func directive<Directive>(_ directive: Directive) -> Interface where Directive: InterfaceDirective {
        directives.append(directive)
        return self
    }
}
