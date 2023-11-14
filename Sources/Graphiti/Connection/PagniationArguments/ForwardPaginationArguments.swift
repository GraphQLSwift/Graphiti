public protocol ForwardPaginatable: Decodable {
    var first: Int? { get }
    var after: String? { get }
}

public struct ForwardPaginationArguments: ForwardPaginatable {
    public let first: Int?
    public let after: String?
    
    public init(first: Int?, after: String?) {
        self.first = first
        self.after = after
    }
}
