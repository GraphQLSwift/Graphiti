public enum TypeReference<Referent> {}

extension TypeReference: Wrapper {
    static var wrappedType: Any.Type {
        return Referent.self
    }

    static var modifier: WrapperModifier {
        return .reference
    }
}
