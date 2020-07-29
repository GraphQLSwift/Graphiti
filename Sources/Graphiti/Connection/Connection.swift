import Foundation
import NIO
import GraphQL

public struct Connection<Node : Encodable> : Encodable {
    let edges: [Edge<Node>]
    let pageInfo: PageInfo
}

@available(OSX 10.15, *)
public extension Connection where Node : Identifiable, Node.ID : LosslessStringConvertible {
    static func id(_ cursor: String) -> Node.ID? {
        cursor.base64Decoded().flatMap({ Node.ID($0) })
    }
    
    static func cursor(_ id: Node.ID) -> String? {
        id.description.base64Encoded()
    }
}

@available(OSX 10.15, *)
public extension EventLoopFuture where Value : Sequence, Value.Element : Encodable & Identifiable, Value.Element.ID : LosslessStringConvertible {
    func connection(from arguments: Paginatable) -> EventLoopFuture<Connection<Value.Element>> {
        flatMapThrowing { value in
            try value.connection(from: arguments)
        }
    }
    
    func connection(from arguments: ForwardPaginatable) -> EventLoopFuture<Connection<Value.Element>> {
        flatMapThrowing { value in
            try value.connection(from: arguments)
        }
    }
    
    func connection(from arguments: BackwardPaginatable) -> EventLoopFuture<Connection<Value.Element>> {
        flatMapThrowing { value in
            try value.connection(from: arguments)
        }
    }
}

@available(OSX 10.15, *)
public extension Sequence where Element : Encodable & Identifiable, Element.ID : LosslessStringConvertible {
    func connection(from arguments: Paginatable) throws -> Connection<Element> {
        try connect(to: Array(self), arguments: PaginationArguments(arguments))
    }
    
    func connection(from arguments: ForwardPaginatable) throws -> Connection<Element> {
        try connect(to: Array(self), arguments: PaginationArguments(arguments))
    }
    
    func connection(from arguments: BackwardPaginatable) throws -> Connection<Element> {
        try connect(to: Array(self), arguments: PaginationArguments(arguments))
    }
}

@available(OSX 10.15, *)
func connect<Node>(
    to elements: [Node],
    arguments: PaginationArguments
) throws -> Connection<Node> where Node : Encodable & Identifiable, Node.ID : LosslessStringConvertible {
    let edges = elements.map { element in
        Edge<Node>(node: element, cursor: Connection<Node>.cursor(element.id)!)
    }
    
    let cursorEdges = slicingCursor(edges: edges, arguments: arguments)
    let countEdges = try slicingCount(edges: cursorEdges, arguments: arguments)
    
    return Connection(
        edges: countEdges,
        pageInfo: PageInfo(
            hasPreviousPage: hasPreviousPage(edges: cursorEdges, arguments: arguments),
            hasNextPage: hasNextPage(edges: cursorEdges, arguments: arguments),
            startCursor: countEdges.first.map({ $0.cursor }),
            endCursor: countEdges.last.map({ $0.cursor })
        )
    )
}

func slicingCursor<Node : Encodable>(
    edges: [Edge<Node>],
    arguments: PaginationArguments
) -> ArraySlice<Edge<Node>> {
    var edges = ArraySlice(edges)
    
    if
        let after = arguments.after,
        let afterIndex = edges
            .firstIndex(where: { $0.cursor == after })?
            .advanced(by: 1)
    {
        edges = edges[afterIndex...]
    }
    
    if
        let before = arguments.before,
        let beforeIndex = edges
            .firstIndex(where: { $0.cursor == before })
    {
        edges = edges[..<beforeIndex]
    }
    
    return edges
}

func slicingCount<Node : Encodable>(
    edges: ArraySlice<Edge<Node>>,
    arguments: PaginationArguments
) throws -> Array<Edge<Node>> {
    var edges = edges
    
    if let first = arguments.first {
        if first < 0 {
            throw GraphQLError(
                message: #"Invalid agurment "first". Argument must be a positive integer."#
            )
        }
        
        edges = edges.prefix(first)
    }
    
    if let last = arguments.last {
        if last < 0 {
            throw GraphQLError(
                message: #"Invalid agurment "last". Argument must be a positive integer."#
            )
        }
        
        edges = edges.suffix(last)
    }
    
    return Array(edges)
}

func hasPreviousPage<Node : Encodable>(
    edges: ArraySlice<Edge<Node>>,
    arguments: PaginationArguments
) -> Bool {
    if let last = arguments.last {
        return edges.count > last
    }
    
    return false
}

func hasNextPage<Node : Encodable>(
    edges: ArraySlice<Edge<Node>>,
    arguments: PaginationArguments
) -> Bool {
    if let first = arguments.first {
        return edges.count > first
    }
    
    return false
}

extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}
