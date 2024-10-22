// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Graphiti",
    products: [
        .library(name: "Graphiti", targets: ["Graphiti"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "Graphiti", dependencies: ["GraphQL"]),
        .testTarget(name: "GraphitiTests", dependencies: ["Graphiti"], resources: [
            .copy("FederationTests/GraphQL"),
        ]),
    ]
)
