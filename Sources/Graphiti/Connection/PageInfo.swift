public struct PageInfo: Codable, Sendable {
    public let hasPreviousPage: Bool
    public let hasNextPage: Bool
    public let startCursor: String?
    public let endCursor: String?

    public init(
        hasPreviousPage: Bool,
        hasNextPage: Bool,
        startCursor: String? = nil,
        endCursor: String? = nil
    ) {
        self.hasPreviousPage = hasPreviousPage
        self.hasNextPage = hasNextPage
        self.startCursor = startCursor
        self.endCursor = endCursor
    }
}
