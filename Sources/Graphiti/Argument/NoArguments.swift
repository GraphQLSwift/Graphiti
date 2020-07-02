public struct NoArguments : Decodable, Keyable {
    public struct Keys : RawRepresentable {
        public init?(rawValue: String) {
            return nil
        }
        
        public var rawValue: String
    }
    
    init() {}
}
