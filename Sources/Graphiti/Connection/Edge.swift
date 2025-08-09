protocol Edgeable: Sendable {
    associatedtype Node
    var node: Node { get }
    var cursor: String { get }
}

public struct Edge<Node: Sendable>: Edgeable {
    public let node: Node
    public let cursor: String
}
