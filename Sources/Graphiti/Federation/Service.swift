import GraphQL

struct Service: Codable {
    let sdl: String
}

let serviceType = try! GraphQLObjectType(
    name: "_Service",
    description: "Federation service object",
    fields: [
        "sdl": GraphQLField(type: GraphQLString),
    ]
)
