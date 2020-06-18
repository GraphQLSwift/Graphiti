import GraphQL
import NIO

public protocol Service {
    associatedtype RootType : Keyable
    associatedtype ContextType
    var root: RootType { get }
    var context: ContextType { get }
    var schema: Schema<RootType, ContextType> { get }
}

extension Service {
    public func execute(
        request: String,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<GraphQLResult> {
        return schema.execute(
            request: request,
            root: root,
            context: self.context,
            eventLoopGroup: eventLoopGroup,
            variables: variables,
            operationName: operationName
        )
    }
}
