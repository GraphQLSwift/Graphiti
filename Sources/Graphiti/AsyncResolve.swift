import NIO

public typealias AsyncResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
)  -> (
    _ context: Context,
    _ arguments: Arguments,
    _ eventLoopGroup: EventLoopGroup
) throws -> EventLoopFuture<ResolveType>
