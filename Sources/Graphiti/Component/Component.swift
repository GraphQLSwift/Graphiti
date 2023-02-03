import GraphQL

open class Component<Resolver, Context> {
    let name: String
    var description: String?
    var componentType: ComponentType

    init(name: String, type: ComponentType) {
        self.name = name
        componentType = type
    }

    func update(typeProvider _: SchemaTypeProvider, coders _: Coders) throws {}
    func setGraphQLName(typeProvider _: SchemaTypeProvider) throws {}
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

    /// An index used to sort components into the correct schema build order. This order goes
    /// from "least other type references" to "most". By building in this order we are able to satisfy
    /// hard ordering requirements (interfaces MUST be built before inheriting types), as well as
    /// reduce unnecessary TypeReferences.
    var buildOrder: Int {
        switch self {
        case .none: return 0
        case .scalar: return 1
        case .enum: return 2
        case .interface: return 3
        case .input: return 4
        case .type: return 5
        case .types: return 6
        case .union: return 7
        case .connection: return 8
        case .query: return 9
        case .mutation: return 10
        case .subscription: return 11
        }
    }
}
