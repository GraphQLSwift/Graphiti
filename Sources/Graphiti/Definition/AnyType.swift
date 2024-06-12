final class AnyType: Hashable {
    let type: Any.Type

    init(_ type: Any.Type) {
        self.type = type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: type))
    }

    static func == (lhs: AnyType, rhs: AnyType) -> Bool {
        return lhs.type == rhs.type
    }
}
