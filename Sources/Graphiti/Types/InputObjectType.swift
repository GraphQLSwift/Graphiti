import GraphQL

public final class InputObjectTypeBuilder<Root, Context, Type> {
    var schema: SchemaBuilder<Root, Context>
    
    init(schema: SchemaBuilder<Root, Context>) {
        self.schema = schema
    }
    
    public var description: String? = nil
    
    var fields: InputObjectConfigFieldMap = [:]
    
    /// Export all properties using reflection
    ///
    /// - Throws: Reflection Errors
    public func exportFields() throws {
        for property in try properties(Type.self) {
            let field = InputObjectField(type: try schema.getInputType(from: property.type, field: property.key))
            fields[property.key] = field
        }
    }
}

