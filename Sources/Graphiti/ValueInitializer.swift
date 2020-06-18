public final class ValueInitializer<EnumType : Enumerable> {
    let value: Value<EnumType>
    
    init(_ value: Value<EnumType>) {
        self.value = value
    }

    @discardableResult
    public func description(_ description: String) -> Self {
        value.description = description
        return self
    }
    
    @discardableResult
    public func deprecationReason(_ deprecationReason: String) -> Self {
        value.deprecationReason = deprecationReason
        return self
    }
}
