public final class Value<EnumType: Encodable & RawRepresentable> where EnumType.RawValue == String {
    let value: EnumType
    var description: String?
    var deprecationReason: String?

    init(
        value: EnumType
    ) {
        self.value = value
    }
}

public extension Value {
    convenience init(_ value: EnumType) {
        self.init(value: value)
    }

    @discardableResult
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }

    @discardableResult
    func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
