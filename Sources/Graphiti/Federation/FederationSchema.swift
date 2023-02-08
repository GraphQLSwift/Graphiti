import Foundation
import GraphQL

final class FederationSchema<Resolver, Context>: PartialSchema<Resolver, Context> where Resolver: FederationResolver, Resolver.Context == Context {
    private let entityTypes: [FederationEntity.Type]

    init(entityTypes: [FederationEntity.Type]) {
        self.entityTypes = entityTypes
    }

    @TypeDefinitions
    override var types: Types {
        Scalar(Map.self, as: "_Any")

        Union(FederationEntity.self, as: "_Entity", members: entityTypes)

        Type(FederationServiceType.self, as: "_Service") {
            Field("sdl", at: \.sdl)
        }
    }

    @FieldDefinitions
    override var query: Fields {
        Field("_entities", at: Resolver.entityResolver, as: [FederationEntity?].self) {
            Argument("representations", at: \.representations)
        }
        Field("_service", at: Resolver.serviceResolver)
    }
}
