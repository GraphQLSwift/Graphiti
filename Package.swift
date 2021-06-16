// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Graphiti",
    products: [
        .library(name: "Graphiti", targets: ["Graphiti"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", .upToNextMajor(from: "1.3.0")),
        .package(url: "https://github.com/apple/swift-collections", .upToNextMajor(from: "0.0.3"))
    ],
    targets: [
        .target(name: "Graphiti", dependencies: [
            "GraphQL",
            .product(name: "OrderedCollections", package: "swift-collections"),
        ]),
        .testTarget(name: "GraphitiTests", dependencies: ["Graphiti"]),
    ]
)
