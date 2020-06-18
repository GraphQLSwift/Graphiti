public final class Value<EnumType : Encodable & RawRepresentable> where EnumType.RawValue == String {
    let value: EnumType
    var description: String?
    var deprecationReason: String?
    
    init(
        value: EnumType
    ) {
        self.value = value
    }
}
