import GraphQL

public class Key<ObjectType, Resolver, Context, Arguments: Codable>: KeyComponent<
    ObjectType,
    Resolver,
    Context
> {
    let arguments: [ArgumentComponent<Arguments>]
    let resolve: AsyncResolve<Resolver, Context, Arguments, ObjectType?>

    override func mapMatchesArguments(_ map: Map, coders: Coders) -> Bool {
        let args = try? coders.decoder.decode(Arguments.self, from: map)
        return args != nil
    }

    override func resolveMap(
        resolver: Resolver,
        context: Context,
        map: Map,
        coders: Coders
    ) async throws -> Any? {
        let arguments = try coders.decoder.decode(Arguments.self, from: map)
        return try await resolve(resolver)(context, arguments)
    }

    override func validate(
        againstFields fieldNames: [String]
    ) throws {
        // Ensure that every argument is included in the provided field list
        for name in arguments.map({ $0.getName() }) {
            if !fieldNames.contains(name) {
                throw GraphQLError(message: "Argument name not found in type fields: \(name)")
            }
        }
    }

    func arguments(typeProvider: TypeProvider, coders: Coders) throws -> GraphQLArgumentConfigMap {
        var map: GraphQLArgumentConfigMap = [:]

        for argument in arguments {
            let (name, argument) = try argument.argument(typeProvider: typeProvider, coders: coders)
            map[name] = argument
        }

        return map
    }

    init(
        arguments: [ArgumentComponent<Arguments>],
        asyncResolve: @escaping AsyncResolve<Resolver, Context, Arguments, ObjectType?>
    ) {
        self.arguments = arguments
        resolve = asyncResolve
    }

    convenience init(
        arguments: [ArgumentComponent<Arguments>],
        syncResolve: @escaping SyncResolve<Resolver, Context, Arguments, ObjectType?>
    ) {
        let asyncResolve: AsyncResolve<Resolver, Context, Arguments, ObjectType?> = { type in
            { context, arguments in
                try syncResolve(type)(context, arguments)
            }
        }

        self.init(arguments: arguments, asyncResolve: asyncResolve)
    }
}
