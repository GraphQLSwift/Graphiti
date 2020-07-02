protocol Edgeable {
    associatedtype T : Encodable
    var node: T { get }
    var cursor: String { get }
}

struct Edge<T : Encodable> : Edgeable, Encodable {
    let node: T
    let cursor: String
}
