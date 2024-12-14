public enum Reflection {
    public static func isProtocol(type: Any.Type) -> Bool {
        let description = String(describing: Swift.type(of: type))
        return description.hasSuffix("Protocol")
    }

    public static func name<Subject>(for instance: Subject) -> String {
        var typeName: [Character] = []
        var genericArgument: [Character] = []
        var parsingTypeName = true

        for character in String(describing: instance) {
            guard character != " " else {
                break
            }

            if ["(", ")"].contains(character) {
                continue
            }

            if character == "<" {
                parsingTypeName = false
                continue
            }

            if character == ">" {
                parsingTypeName = true
                continue
            }

            if parsingTypeName {
                typeName.append(character)
            } else {
                genericArgument.append(character)
            }
        }

        return String(genericArgument + typeName)
    }
}
