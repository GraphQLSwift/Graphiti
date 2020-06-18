public final class ValuesInitializer<RootType : Keyable, Context, EnumType : Enumerable> {
    var values: [Value<EnumType>] = []
    
    public func value(_ value: EnumType) -> ValueInitializer<EnumType> {
        let value = Value(value: value)
        values.append(value)
        return ValueInitializer(value)
    }
}
