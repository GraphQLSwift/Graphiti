public protocol BackwardPaginatable: Decodable {
    var last: Int? { get }
    var before: String? { get }
}

public struct BackwardPaginationArguments: BackwardPaginatable {
    public let last: Int?
    public let before: String?
    
    public init(last: Int?, before: String?) {
        self.last = last
        self.before = before
    }
}
