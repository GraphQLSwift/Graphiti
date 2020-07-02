struct PageInfo : Codable, Keyable {
    enum Keys : String {
        case hasPreviousPage
        case hasNextPage
        case startCursor
        case endCursor
    }
    
    let hasPreviousPage: Bool
    let hasNextPage: Bool
    let startCursor: String?
    let endCursor: String?
}
