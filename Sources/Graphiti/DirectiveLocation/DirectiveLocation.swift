import GraphQL

public final class DirectiveLocation<DirectiveType> {
    let location: GraphQL.DirectiveLocation
    
    init(location: GraphQL.DirectiveLocation) {
        self.location = location
    }
}

// MARK: - Schema

// MARK: - Scalar

// MARK: - Object

public struct ObjectDirectiveLocation {
    public static let object = ObjectDirectiveLocation()
}

public extension DirectiveLocation {
    convenience init(_ location: ObjectDirectiveLocation, at keyPath: KeyPath<DirectiveType, ConfigureObject>) {
        self.init(location: .object)
    }
}

// MARK: - FieldDefinition

public struct FieldDefinitionDirectiveLocation {
    public static let fieldDefinition = FieldDefinitionDirectiveLocation()
}

public extension DirectiveLocation {
    convenience init(_ location: FieldDefinitionDirectiveLocation, at keyPath: KeyPath<DirectiveType, ConfigureFieldDefinition>) {
        self.init(location: .fieldDefinition)
    }
}

// MARK: - ArgumentDefinition
// MARK: - Interface
// MARK: - Union
// MARK: - Enum
// MARK: - EnumValue
// MARK: - InputObject
// MARK: - InputFieldDefinition
