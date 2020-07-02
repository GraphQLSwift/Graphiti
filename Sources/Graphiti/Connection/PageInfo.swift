struct PageInfo : Codable {
    let hasPreviousPage: Bool
    let hasNextPage: Bool
    let startCursor: String?
    let endCursor: String?
}
