public enum Reflection {
    public static func isProtocol(type: Any.Type) -> Bool {
        let description = String(describing: Swift.type(of: type))
        return description.hasSuffix("Protocol")
    }
    
    public static func isEncodable(type: Any.Type) -> Bool {
        if isProtocol(type: type) {
            return true
        }

        if let type = type as? Wrapper.Type {
            return isEncodable(type: type.wrappedType)
        }

        return type is Encodable.Type
    }

    public static func name<Subject>(for instance: Subject) -> String {
        let name = String(describing: instance)
        // In Swift 4, String(describing: MyClass.self) appends ' #1' for locally defined classes,
        // which we consider invalid for a type name. Strip this by copying until the first space.
        var workingString = name
        
        if name.hasPrefix("(") {
            workingString = String(name.dropFirst())
        }
        
        var newName: [Character] = []
        
        for character in workingString {
            if character != " " {
                newName.append(character)
            } else {
                break
            }
        }

        return String(newName)
    }
}
