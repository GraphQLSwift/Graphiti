public struct PageInfo: Codable {
    public let hasPreviousPage: Bool
    public let hasNextPage: Bool
    public let startCursor: String?
    public let endCursor: String?
}
