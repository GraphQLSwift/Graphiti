import NIO

public typealias SubscribeResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
) -> (
    _ context: Context,
    _ arguments: Arguments,
    _ eventLoopGroup: EventLoopGroup
) throws -> EventLoopFuture<ResolveType>
