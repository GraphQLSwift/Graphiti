import NIO

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public typealias ConcurrentResolve<ObjectType, Context, Arguments, ResolveType> = (
    _ object: ObjectType
) -> (
    _ context: Context,
    _ arguments: Arguments
) async throws -> ResolveType

#endif
