import Foundation
import NIO
import GraphQL

public struct Connection<T : Encodable> : Encodable {
    let edges: [Edge<T>]
    let pageInfo: PageInfo
}

@available(OSX 10.15, *)
public extension EventLoopFuture where Value : Sequence, Value.Element : Codable & Identifiable {
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
extension Sequence where Element : Codable & Identifiable {
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
func connect<T : Codable & Identifiable>(
    to elements: [T],
    arguments: PaginationArguments
) throws -> Connection<T> {
    let edges = elements.map { element in
        Edge<T>(node: element, cursor: "\(element.id)".base64Encoded()!)
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

func slicingCursor<T : Codable>(
    edges: [Edge<T>],
    arguments: PaginationArguments
) -> ArraySlice<Edge<T>> {
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

func slicingCount<T : Codable>(
    edges: ArraySlice<Edge<T>>,
    arguments: PaginationArguments
) throws -> Array<Edge<T>> {
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

func hasPreviousPage<T : Codable>(
    edges: ArraySlice<Edge<T>>,
    arguments: PaginationArguments
) -> Bool {
    if let last = arguments.last {
        return edges.count > last
    }
    
    return false
}

func hasNextPage<T : Codable>(
    edges: ArraySlice<Edge<T>>,
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
