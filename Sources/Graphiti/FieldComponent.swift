import GraphQL

public class FieldComponent<ObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
    var description: String? = nil
    var deprecationReason: String? = nil
    var argumentsDescriptions: [String: String] = [:]
    var argumentsDefaultValues: [String: AnyEncodable] = [:]
    
    func field(provider: TypeProvider) throws -> (String, GraphQLField) {
        fatalError()
    }
}
