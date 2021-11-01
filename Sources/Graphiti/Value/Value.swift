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
    
    @available(*, deprecated, message: "Use a string literal above a component to give it a description.")
    func description(_ description: String) -> Self {
        self.description = description
        return self
    }
    
    @available(*, deprecated, message: "Use deprecated(reason:).")
    func deprecationReason(_ deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
    
    func deprecated(reason deprecationReason: String) -> Self {
        self.deprecationReason = deprecationReason
        return self
    }
}
