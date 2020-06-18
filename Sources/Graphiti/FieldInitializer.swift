import GraphQL

public final class FieldInitializer<ObjectType, Keys : RawRepresentable, Context, Arguments : Decodable> where Keys.RawValue == String {
    var field: FieldComponent<ObjectType, Keys, Context>
    
    init(_ field: FieldComponent<ObjectType, Keys, Context>) {
        self.field = field
    }
    
    @discardableResult
    public func description(_ description: String) -> Self {
        field.description = description
        return self
    }
    
    @discardableResult
    public func deprecationReason(_ deprecationReason: String) -> Self {
        field.deprecationReason = deprecationReason
        return self
    }
    
    @discardableResult
    public func argument<Argument>(
        _ name: Keys,
        at keyPath: KeyPath<Arguments, Argument>,
        description: String
    ) -> Self {
        field.argumentsDescriptions[name.rawValue] = description
        return self
    }
    
    @discardableResult
    public func argument<Argument : Encodable>(
        _ name: Keys,
        at keyPath: KeyPath<Arguments, Argument>,
        defaultValue: Argument
    ) -> Self {
       field.argumentsDefaultValues[name.rawValue] = AnyEncodable(defaultValue)
       return self
    }
}
