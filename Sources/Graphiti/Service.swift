import GraphQL
import NIO

public protocol Service {
    associatedtype RootType : Keyable
    associatedtype ContextType
    var root: RootType { get }
    var schema: Schema<RootType, ContextType> { get }
}

extension Service {
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
