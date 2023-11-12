protocol Edgeable {
    associatedtype Node
    var node: Node { get }
    var cursor: String { get }
}

public struct Edge<Node>: Edgeable {
    public let node: Node
    public let cursor: String
}
