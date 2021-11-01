import GraphQL
#warning("TODO: Create Directive component")

struct ArgumentConfiguration {
    let name: String
    var defaultValue: AnyEncodable?
}

struct FieldConfiguration<Context> {
    var name: String
    var description: String?
    var deprecationReason: String?
    var arguments: [ArgumentConfiguration]
    var resolve: AsyncResolve<Any, Context, Map, Any?>
}

protocol FieldDefinitionDirective {
    associatedtype Context
    func fieldDefinition(fieldDefinition: inout FieldConfiguration<Context>)
}

struct Deprecated<Context>: FieldDefinitionDirective {
    let reason: String

    func fieldDefinition(fieldDefinition: inout FieldConfiguration<Context>) {
        fieldDefinition.deprecationReason = reason
    }
}

func directive() throws {
    //
    // "Marks a field or enum value as deprecated"
    // Directive(Deprecated.self) {
    //     "The reason for the deprecation"
    //     Argument("reason", at: \.reason)
    //         .defaultValue("No longer supported")
    // } on: {
    //     Location(\.fieldDefinition)
    //     Location(\.enumValue)
    // }
    // .repeatable()
    //
    //
    // Type(User.self) {
    //     Field("age", of: Int.self)
    //         .directive(Deprecated(reason: "Use dateOfBirth instead")) // We need to keep track of the directives applied to check for "repeatable"
    // }
    //
    
    let directive = try GraphQLDirective(
        name: "deprecated",
        description: "Marks a field as deprecated",
        locations: [.fieldDefinition, .enumValue],
        args: [
            "reason": GraphQLArgument(
                type: GraphQLString,
                description: "The reason for the deprecation",
                defaultValue: .string("No longer supported")
            )
        ]
    )
}
