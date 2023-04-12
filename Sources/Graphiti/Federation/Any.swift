import GraphQL

let anyType = try! GraphQLScalarType(
    name: "_Any",
    description: "Scalar representing the JSON form of any type. A __typename field is required.",
    serialize: { try map(from: $0) },
    parseValue: { $0 },
    parseLiteral: { ast in
        ast.map
    }
)
