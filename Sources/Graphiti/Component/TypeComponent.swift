/// Type-based components (`Enum`, `Input`, `Interface`, `Scalar`, `Type`, `Union`) subclass from this class
open class TypeComponent<Resolver, Context>: Component<Resolver, Context> {
    var entityKeys: [(fields: String, keyType: FederationEntityKey.Type)] = []
}

public extension TypeComponent {
    func key(_ type: FederationEntityKey.Type) -> Self {
        entityKeys.append((type.fields, type))
        return self
    }
}
