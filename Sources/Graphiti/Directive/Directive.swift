import GraphQL

public final class Directive<Resolver, Context, DirectiveType>: Component<Resolver, Context> where DirectiveType: Decodable {
    private let locations: [GraphQL.DirectiveLocation]
    private let arguments: [ArgumentComponent<DirectiveType>]
    
    override func update(typeProvider: SchemaTypeProvider, coders: Coders) throws {
        #warning("TODO: Make description optional in GraphQLDirective")
//        guard let description = self.description else {
//            throw GraphQLError(message: "No description. Descriptions are required for directives")
//        }
        
        let directive = try GraphQLDirective(
            name: name,
            description: description ?? "",
            locations: locations,
            args: try arguments(typeProvider: typeProvider, coders: coders)
        )
        
        #warning("TODO: Guarantee there is no other directive with same name")
        typeProvider.directives.append(directive)
    }
    
    func arguments(typeProvider: TypeProvider, coders: Coders) throws -> GraphQLArgumentConfigMap {
        var map: GraphQLArgumentConfigMap = [:]
        
        for argument in arguments {
            let (name, argument) = try argument.argument(typeProvider: typeProvider, coders: coders)
            map[name] = argument
        }
        
        return map
    }
    
    private init(
        type: DirectiveType.Type,
        name: String?,
        locations: [GraphQL.DirectiveLocation],
        arguments: [ArgumentComponent<DirectiveType>]
    ) {
        #warning("TODO: Throw if name equals pre-defined directives")
        self.locations = locations
        self.arguments = arguments
        
        super.init(
            name: name ?? Reflection.name(for: DirectiveType.self).firstCharacterLowercased()
        )
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

extension StringProtocol {
    func firstCharacterLowercased() -> String {
        prefix(1).lowercased() + dropFirst()
    }
}

public extension Directive {
    convenience init(
        _ type: DirectiveType.Type,
        as name: String? = nil,
        @ArgumentComponentBuilder<DirectiveType> argument: () -> ArgumentComponent<DirectiveType>,
        @DirectiveLocationBuilder<DirectiveType> on locations: () -> [DirectiveLocation<DirectiveType>]
    ) {
        self.init(
            type: type,
            name: name,
            locations: locations().map({ $0.location }),
            arguments: [argument()]
        )
    }
    
    convenience init(
        _ type: DirectiveType.Type,
        as name: String? = nil,
        @ArgumentComponentBuilder<DirectiveType> arguments: () -> [ArgumentComponent<DirectiveType>] = {[]},
        @DirectiveLocationBuilder<DirectiveType> on locations: () -> [DirectiveLocation<DirectiveType>]
    ) {
        self.init(
            type: type,
            name: name,
            locations: locations().map({ $0.location }),
            arguments: arguments()
        )
    }
}




