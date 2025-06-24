public typealias SyncResolve<ObjectType, Context, Arguments, ResolveType> = @Sendable (
    _ object: ObjectType
) -> (
    _ context: Context,
    _ arguments: Arguments
) throws -> ResolveType
