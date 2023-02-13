import Foundation
import GraphQL
import NIO

struct EntityArguments: Codable {
    let representations: [Map]
}

struct EntityRepresentation: Codable {
    let __typename: String
}

func entityType(_ federatedTypes: [GraphQLObjectType]) -> GraphQLUnionType {
    return try! GraphQLUnionType(
        name: "_Entity",
        description: "Any type that has a federated key definition",
        types: federatedTypes
    )
}
