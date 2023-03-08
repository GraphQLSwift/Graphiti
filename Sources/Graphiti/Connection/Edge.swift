public protocol Edgeable {
    associatedtype Node: Encodable
    var node: Node { get }
    var cursor: String { get }
}

public struct Edge<Node: Encodable>: Edgeable, Encodable {
    public let node: Node
    public let cursor: String
}
