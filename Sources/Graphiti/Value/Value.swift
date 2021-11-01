public final class Value<EnumType : Encodable & RawRepresentable>: ExpressibleByStringLiteral where EnumType.RawValue == String {
    let value: EnumType
    var description: String?
    var deprecationReason: String?
    
    init(
        value: EnumType
    ) {
        self.value = value
    }
    
    public required init(unicodeScalarLiteral string: String) {
        self.value = EnumType(rawValue: "")!
        self.description = string
    }
    
    public required init(extendedGraphemeClusterLiteral string: String) {
        self.value = EnumType(rawValue: "")!
        self.description = string
    }
    
    public required init(stringLiteral string: StringLiteralType) {
        self.value = EnumType(rawValue: "")!
        self.description = string
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
    
    @available(*, deprecated, message: "Use deprecated(reason:).")
    @discardableResult
    func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
    
    @discardableResult
    func deprecated(reason deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
