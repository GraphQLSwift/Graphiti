import GraphQL

public class EnumValueComponent<EnumType>: ExpressibleByStringLiteral {
    var description: String? = nil
    
    func enumValue(typeProvider: SchemaTypeProvider, coders: Coders) throws -> (String, GraphQLEnumValue) {
        fatalError()
    }

    init() {}
    
    public required init(stringLiteral string: StringLiteralType) {
        self.description = string
    }
}
