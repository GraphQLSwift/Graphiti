import GraphQL
import Runtime

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
    public func exportFields(excluding: String...) throws {
        
        let info = try typeInfo(of: Type.self)
        
        for property in info.properties {
            if !excluding.contains(property.name) {
                let field = InputObjectField(type: try schema.getInputType(from: property.type, field: property.name))
                fields[property.name] = field
            }
        }
    }
    
    public func addFieldMap(key: String, fieldMap: InputObjectField) {
        fields[key] = fieldMap
    }
}

