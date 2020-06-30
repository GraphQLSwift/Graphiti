public protocol BackwardPaginatable : Decodable {
    var last: Int? { get }
    var before: String? { get }
}

public struct BackwardPaginationArguments : BackwardPaginatable {
    public let last: Int?
    public let before: String?
}
