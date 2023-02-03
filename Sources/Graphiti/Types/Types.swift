import GraphQL

@available(*, deprecated, message: "No longer use this. Instead define types using `Type`.")
public final class Types<Resolver, Context>: Component<Resolver, Context> {
    let types: [Any.Type]

    override func update(typeProvider: SchemaTypeProvider, coders _: Coders) throws {
        typeProvider.types = try types.map {
            try typeProvider.getNamedType(from: $0)
        }
    }

    init(types: [Any.Type]) {
        self.types = types
        super.init(
            name: "",
            type: .types
        )
    }

    public convenience init(_ types: Any.Type...) {
        self.init(types: types)
    }
}
