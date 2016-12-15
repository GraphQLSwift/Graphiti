import protocol GraphQL.MapFallibleRepresentable
@_exported import enum GraphQL.Map
@_exported import enum GraphQL.MapError

final class AnyType : Hashable {
    let type: Any.Type

    init(_ type: Any.Type) {
        self.type = type
    }

    var hashValue: Int {
        return String(describing: type).hashValue
    }

    static func == (lhs: AnyType, rhs: AnyType) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

func isProtocol(type: Any.Type) -> Bool {
    let description = String(describing: type(of: type))
    return description.hasSuffix("Protocol")
}

func fixName(_ name: String) -> String {
    if name.hasPrefix("(") {
        var newName: [Character] = []

        for character in String(name.characters.dropFirst()).characters {
            if character != " " {
                newName.append(character)
            } else {
                break
            }
        }

        return String(newName)
    }

    return name
}


func isMapFallibleRepresentable(type: Any.Type) -> Bool {
    if isProtocol(type: type) {
        return true
    }

    if let type = type as? Wrapper.Type {
        return isMapFallibleRepresentable(type: type.wrappedType)
    }

    return type is MapFallibleRepresentable.Type
}

