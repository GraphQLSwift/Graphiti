@_functionBuilder
public struct ValueBuilder<EnumType : Encodable & RawRepresentable> where EnumType.RawValue == String {
    public static func buildExpression(_ value: Value<EnumType>) -> Value<EnumType> {
        value
    }

    public static func buildBlock(_ value: Value<EnumType>...) -> [Value<EnumType>] {
        value
    }
}
