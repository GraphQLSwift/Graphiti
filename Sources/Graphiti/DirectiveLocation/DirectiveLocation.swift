import GraphQL

public final class DirectiveLocation<DirectiveType> {
    let location: GraphQL.DirectiveLocation
    
    init(location: GraphQL.DirectiveLocation) {
        self.location = location
    }
}

public extension DirectiveLocation {
    convenience init(_ location: KeyPath<DirectiveType, (inout FieldConfiguration) -> Void>) {
        self.init(location: .fieldDefinition)
    }
}
