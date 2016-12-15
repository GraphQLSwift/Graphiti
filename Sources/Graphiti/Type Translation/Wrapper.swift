enum WrapperModifier {
    case optional
    case list
    case reference
}

protocol Wrapper {
    static var wrappedType: Any.Type { get }
    static var modifier: WrapperModifier { get }
}

extension Optional : Wrapper {
    static var wrappedType: Any.Type {
        return Wrapped.self
    }

    static var modifier: WrapperModifier {
        return .optional
    }
}

extension Array : Wrapper {
    static var wrappedType: Any.Type {
        return Element.self
    }

    static var modifier: WrapperModifier {
        return .list
    }
}

public struct TypeReference<Referent> {}

extension TypeReference : Wrapper {
    static var wrappedType: Any.Type {
        return Referent.self
    }

    static var modifier: WrapperModifier {
        return .reference
    }
}
