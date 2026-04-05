import GraphQL

public protocol API {
    associatedtype Resolver: Sendable
    associatedtype ContextType: Sendable
    var resolver: Resolver { get }
    var schema: Schema<Resolver, ContextType> { get }
}

extension API {
    public func execute(
        request: String,
        context: ContextType,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [@Sendable (ValidationContext) -> Visitor] = []
    ) async throws -> GraphQLResult {
        return try await schema.execute(
            request: request,
            resolver: resolver,
            context: context,
            variables: variables,
            operationName: operationName,
            validationRules: validationRules
        )
    }

    public func execute(
        request: GraphQLRequest,
        context: ContextType,
        validationRules: [@Sendable (ValidationContext) -> Visitor] = []
    ) async throws -> GraphQLResult {
        return try await execute(
            request: request.query,
            context: context,
            variables: request.variables,
            operationName: request.operationName,
            validationRules: validationRules
        )
    }

    public func subscribe(
        request: String,
        context: ContextType,
        variables: [String: Map] = [:],
        operationName: String? = nil,
        validationRules: [@Sendable (ValidationContext) -> Visitor] = []
    ) async throws -> Result<AsyncThrowingStream<GraphQLResult, Error>, GraphQLErrors> {
        return try await schema.subscribe(
            request: request,
            resolver: resolver,
            context: context,
            variables: variables,
            operationName: operationName,
            validationRules: validationRules
        )
    }

    public func subscribe(
        request: GraphQLRequest,
        context: ContextType,
        validationRules: [@Sendable (ValidationContext) -> Visitor] = []
    ) async throws -> Result<AsyncThrowingStream<GraphQLResult, Error>, GraphQLErrors> {
        return try await subscribe(
            request: request.query,
            context: context,
            variables: request.variables,
            operationName: request.operationName,
            validationRules: validationRules
        )
    }
}
