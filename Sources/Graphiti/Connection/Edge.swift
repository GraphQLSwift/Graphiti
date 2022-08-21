protocol Edgeable {
    associatedtype Node: Encodable
    var node: Node { get }
    var cursor: String { get }
}

struct Edge<Node: Encodable>: Edgeable, Encodable {
    let node: Node
    let cursor: String
}
