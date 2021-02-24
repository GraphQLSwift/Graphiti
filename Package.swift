// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Graphiti",
    products: [
        .library(name: "Graphiti", targets: ["Graphiti"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", .upToNextMajor(from: "1.1.7")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.1.0"))
    ],
    targets: [
        .target(name: "Graphiti", dependencies: ["GraphQL", "RxSwift"]),
        .testTarget(name: "GraphitiTests", dependencies: ["Graphiti"]),
    ]
)
