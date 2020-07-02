import GraphQL
import NIO

public protocol API {
    associatedtype RootType
    associatedtype ContextType
    var root: RootType { get }
    var schema: Schema<RootType, ContextType> { get }
}

extension API {
    public func execute(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<GraphQLResult> {
        return schema.execute(
            request: request,
            root: root,
            context: context,
            eventLoopGroup: eventLoopGroup,
            variables: variables,
            operationName: operationName
        )
    }
}
