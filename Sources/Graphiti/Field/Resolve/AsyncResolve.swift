
public typealias AsyncResolve<ObjectType, Context, Arguments, ResolveType> = @Sendable (
    _ object: ObjectType
) -> (
    _ context: Context,
    _ arguments: Arguments
) async throws -> ResolveType
