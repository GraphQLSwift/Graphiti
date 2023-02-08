import Foundation
import GraphQL
import NIO

public struct FederationEntityResolverArguments: Codable {
    public let representations: [Map]
}

public protocol FederationResolver {
    associatedtype Context
    static var entityKeys: [(entity: FederationEntity.Type, keys: [FederationEntityKey.Type])] { get }
    static var encoder: JSONEncoder { get }
    static var decoder: JSONDecoder { get }
    var sdl: String { get }
    func entityResolver(context: Context, arguments: FederationEntityResolverArguments, group: EventLoopGroup) -> EventLoopFuture<[FederationEntity?]>
    func serviceResolver(context: Context, arguments: NoArguments) -> FederationServiceType
    func entity(context: Context, key: FederationEntityKey, group: EventLoopGroup) -> EventLoopFuture<FederationEntity?>
}

#if compiler(>=5.7)

public extension FederationResolver {
    func entityResolver(context: Context, arguments: FederationEntityResolverArguments, group: EventLoopGroup) -> EventLoopFuture<[FederationEntity?]> {
        return arguments.representations
            .map { entityKey(representation: $0) }
            .map { key in
                guard let key = key else { return group.next().makeSucceededFuture(nil) }
                return entity(context: context, key: key, group: group)
            }
            .flatten(on: group)
    }

    func entityKey(representation: Map) -> FederationEntityKey? {
        guard
            let encoded = try? Self.encoder.encode(representation),
            let typename = representation["__typename"].string,
            let keyTypes = Self.entityKeys.first(where: { $0.entity.typename == typename })?.keys
        else { return nil }

        for keyType in keyTypes {
            guard let key = try? Self.decoder.decode(keyType, from: encoded) else { continue }
            return key
        }

        return nil
    }

    func serviceResolver(context: Context, arguments: NoArguments) -> FederationServiceType {
        FederationServiceType(sdl: sdl)
    }
}

#endif
