/// A partial schema that declare a set of type, query, mutation, and/or subscription definition
/// which can be compiled together into 1 schema.
open class PartialSchema<Resolver, Context> {
    /// A custom parameter attribute that constructs type definitions from closures.
    public typealias TypeDefinitions = TypeComponentBuilder<Resolver, Context>

    /// A custom parameter attribute that constructs operation field definitions from closures.
    public typealias FieldDefinitions = FieldComponentBuilder<Resolver, Context>

    /// A type that represents a set of type definitions
    public typealias Types = [TypeComponent<Resolver, Context>]

    /// A type that represents a set of operation field definitions
    public typealias Fields = [FieldComponent<Resolver, Context>]

    /// Stored predefined "default" properties for a instance-based declaration
    private let tdef: Types
    private let qdef: Fields
    private let mdef: Fields
    private let sdef: Fields

    public init(
        @TypeDefinitions types: () -> Types = { [] },
        @FieldDefinitions query: () -> Fields = { [] },
        @FieldDefinitions mutation: () -> Fields = { [] },
        @FieldDefinitions subscription: () -> Fields = { [] }
    ) {
        tdef = types()
        qdef = query()
        mdef = mutation()
        sdef = subscription()
    }

    /// Definitions of types
    open var types: Types { tdef }

    /// Definitions of query operation fields
    open var query: Fields { qdef }

    /// Definitions of mutation operation fields
    open var mutation: Fields { mdef }

    /// Definitions of subscription operation fields
    open var subscription: Fields { sdef }
}

public extension Schema {
    /// Create a schema from partial schemas
    /// - Parameter partials: Partial schemas that declare types, query, mutation, and/or subscription definiton
    /// - Returns: A compiled schema will all definitions given from the partial schemas
    static func create(
        from partials: [PartialSchema<Resolver, Context>]
    ) throws -> Schema<Resolver, Context> {
        try SchemaBuilder(Resolver.self, Context.self)
            .use(partials: partials)
            .build()
    }
}
