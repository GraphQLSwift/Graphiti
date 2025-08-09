import GraphQL

public class KeyComponent<ObjectType, Resolver, Context>: @unchecked Sendable {
    func mapMatchesArguments(_: Map, coders _: Coders) -> Bool {
        fatalError()
    }

    func resolveMap(
        resolver _: Resolver,
        context _: Context,
        map _: Map,
        coders _: Coders
    ) async throws -> (any Sendable)? {
        fatalError()
    }

    func validate(
        againstFields _: [String]
    ) throws {
        fatalError()
    }
}
