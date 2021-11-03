@resultBuilder
public struct ValueBuilder<EnumType> where EnumType: Encodable & RawRepresentable, EnumType.RawValue == String {
    public static func buildExpression(_ value: EnumValueComponent<EnumType>) -> EnumValueComponent<EnumType> {
        value
    }

    public static func buildBlock(_ value: EnumValueComponent<EnumType>...) -> [EnumValueComponent<EnumType>] {
        value
    }
}
