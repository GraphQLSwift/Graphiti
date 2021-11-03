import GraphQL

public final class DirectiveLocation<DirectiveType> {
    let location: GraphQL.DirectiveLocation
    
    init(location: GraphQL.DirectiveLocation) {
        self.location = location
    }
}

// MARK: - Query

// MARK: - Mutation

// MARK: - Subscription

// MARK: - Field

public struct FieldDirectiveLocation {
    public static let field = FieldDirectiveLocation()
}

public protocol FieldDirective {
    func field()
}

public extension DirectiveLocation {
    convenience init(_ location: FieldDirectiveLocation) where DirectiveType: FieldDirective {
        self.init(location: .field)
    }
}

// MARK: - FragmentDefinition

// MARK: - FragmentSpread

// MARK: - InlineFragment

// MARK: - VariableDefinition

// MARK: - Schema

// MARK: - Scalar

// MARK: - Object

public struct ObjectDirectiveLocation {
    public static let object = ObjectDirectiveLocation()
}

public typealias Object = Type

public protocol ObjectDirective {
    func object<Resolver, Context, ObjectType>(object: Object<Resolver, Context, ObjectType>) where ObjectType: Encodable
}

public extension DirectiveLocation {
    convenience init(_ location: ObjectDirectiveLocation) where DirectiveType: ObjectDirective {
        self.init(location: .object)
    }
}

// MARK: - FieldDefinition

public struct FieldDefinitionDirectiveLocation {
    public static let fieldDefinition = FieldDefinitionDirectiveLocation()
}

public protocol FieldDefinitionDirective {
    func fieldDefinition<ObjectType, Context, FieldType, Arguments>(field: Field<ObjectType, Context, FieldType, Arguments>)
}

public extension DirectiveLocation {
    convenience init(_ location: FieldDefinitionDirectiveLocation) where DirectiveType: FieldDefinitionDirective {
        self.init(location: .fieldDefinition)
    }
}

// MARK: - ArgumentDefinition
// MARK: - Interface

public struct InterfaceDirectiveLocation {
    public static let interface = InterfaceDirectiveLocation()
}

public protocol InterfaceDirective {
    func interface<Resolver, Context, InterfaceType>(interface: Interface<Resolver, Context, InterfaceType>)
}

public extension DirectiveLocation {
    convenience init(_ location: InterfaceDirectiveLocation) where DirectiveType: InterfaceDirective {
        self.init(location: .interface)
    }
}

// MARK: - Union
// MARK: - Enum
// MARK: - EnumValue
// MARK: - InputObject
// MARK: - InputFieldDefinition
