import GraphQL

public class KeyComponent<ObjectType, Resolver, Context> {
    func mapMatchesArguments(_: Map, coders _: Coders) -> Bool {
        fatalError()
    }

    func resolveMap(
        resolver _: Resolver,
        context _: Context,
        map _: Map,
        coders _: Coders
    ) async throws -> Any? {
        fatalError()
    }

    func validate(
        againstFields _: [String]
    ) throws {
        fatalError()
    }
}
