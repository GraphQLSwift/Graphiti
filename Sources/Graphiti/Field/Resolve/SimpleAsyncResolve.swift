import NIO

public typealias SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
) -> (
    _ context: Context,
    _ arguments: Arguments
) throws -> EventLoopFuture<ResolveType>
