
@available(OSX 10.15, *)
public struct DefaultCursor<Node: Identifiable>: CursorType where Node.ID: Codable {
    public var id: Node.ID
    
    public init(_ node: Node) {
        self.id = node.id
    }
}

@available(OSX 10.15, *)
extension Identifiable where Self.ID: Codable {
    func cursor() -> DefaultCursor<Self> {
        return DefaultCursor(self)
    }
}
