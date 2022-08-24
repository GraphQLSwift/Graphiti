public typealias SyncResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
) -> (
    _ context: Context,
    _ arguments: Arguments
) throws -> ResolveType
