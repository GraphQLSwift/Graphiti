import GraphQL
import NIO

public class KeyComponent<ObjectType, Resolver, Context> {
    func mapMatchesArguments(_: Map, coders _: Coders) -> Bool {
        fatalError()
    }

    func resolveMap(
        resolver _: Resolver,
        context _: Context,
        map _: Map,
        eventLoopGroup _: EventLoopGroup,
        coders _: Coders
    ) throws -> EventLoopFuture<Any?> {
        fatalError()
    }

    func validate(
        againstFields _: [String]
    ) throws {
        fatalError()
    }
}
