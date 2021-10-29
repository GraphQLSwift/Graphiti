import GraphQL
import NIO

@available(*, deprecated, message: "Use the schema directly.")
public protocol API {
    associatedtype Resolver
    associatedtype ContextType
    var resolver: Resolver { get }
    var schema: Schema<Resolver, ContextType> { get }
}

extension API {
    public func execute(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<GraphQLResult> {
        schema.execute(
            request: request,
            resolver: resolver,
            context: context,
            on: eventLoopGroup,
            variables: variables,
            operationName: operationName
        )
    }
    
    public func subscribe(
        request: String,
        context: ContextType,
        on eventLoopGroup: EventLoopGroup,
        variables: [String: Map] = [:],
        operationName: String? = nil
    ) -> EventLoopFuture<SubscriptionResult> {
        schema.subscribe(
            request: request,
            resolver: resolver,
            context: context,
            on: eventLoopGroup,
            variables: variables,
            operationName: operationName
        )
    }
}
