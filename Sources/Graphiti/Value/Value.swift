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

extension Value {
    public convenience init(_ value: EnumType) {
        self.init(value: value)
    }

    @discardableResult
    public func description(_ description: String) -> Self {
        self.description = description
        return self
    }

    @discardableResult
    public func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
