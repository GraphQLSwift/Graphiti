// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Graphiti",
    products: [
        .library(name: "Graphiti", targets: ["Graphiti"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", .upToNextMajor(from: "2.0.0")),
        .package(path: "../GraphQL")
    ],
    targets: [
        .target(name: "Graphiti", dependencies: ["GraphQL"]),
        .testTarget(name: "GraphitiTests", dependencies: ["Graphiti"]),
    ]
)
