import GraphQL

open class Component<Resolver: Sendable, Context: Sendable> {
    let name: String
    var description: String?
    var componentType: ComponentType

    init(name: String, type: ComponentType) {
        self.name = name
        componentType = type
    }

    func update(typeProvider _: SchemaTypeProvider, coders _: Coders) throws {}
}

public extension Component {
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
}

/// The type of a component. This is used as opposed to runtime type-checking because the
/// component types are typically generics (and therefore hard to type-check).
enum ComponentType {
    case none
    case connection
    case `enum`
    case input
    case interface
    case mutation
    case query
    case scalar
    case subscription
    case type
    case types
    case union
}
