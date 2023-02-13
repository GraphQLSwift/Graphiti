import GraphQL
import NIO

public class KeyComponent<ObjectType, Resolver, Context> {
    func mapMatchesArguments(_ map: Map, coders: Coders) -> Bool {
        fatalError()
    }
    
    func resolveMap(
        resolver: Resolver,
        context: Context,
        map: Map,
        eventLoopGroup: EventLoopGroup,
        coders: Coders
    ) throws -> EventLoopFuture<Any?> {
        fatalError()
    }
    
    func validate(againstFields fieldNames: [String], typeProvider: TypeProvider, coders: Coders) throws {
        fatalError()
    }
}
