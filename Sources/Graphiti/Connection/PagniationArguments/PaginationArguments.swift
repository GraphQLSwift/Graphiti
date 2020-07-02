public protocol Paginatable : ForwardPaginatable, BackwardPaginatable {}

public struct PaginationArguments : Paginatable {
    public let first: Int?
    public let last: Int?
    public let after: String?
    public let before: String?
    
    init(_ arguments: Paginatable) {
        self.first = arguments.first
        self.last = arguments.last
        self.after = arguments.after
        self.before = arguments.before
    }
    
    init(_ arguments: ForwardPaginatable) {
        self.first = arguments.first
        self.last = nil
        self.after = arguments.after
        self.before = nil
    }
    
    init(_ arguments: BackwardPaginatable) {
        self.first = nil
        self.last = arguments.last
        self.after = nil
        self.before = arguments.before
    }
}
