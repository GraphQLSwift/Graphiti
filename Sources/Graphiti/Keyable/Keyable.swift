public protocol Keyable {
    associatedtype Keys : RawRepresentable where Keys.RawValue == String
}

extension Optional : Keyable where Wrapped : Keyable  {
    public typealias Keys = Wrapped.Keys
}
