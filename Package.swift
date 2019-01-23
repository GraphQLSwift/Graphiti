// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Graphiti",
    
    products: [
        .library(name: "Graphiti", targets: ["Graphiti"]),
    ],

    dependencies: [
    .package(url: "https://github.com/SportlabsTechnology/GraphQL.git", .revision("0fb10c111e7593884084ed9d7e3c7ea1012260d9")),
    ],

    targets: [
        .target(name: "Graphiti", dependencies: ["GraphQL"]),
        
        .testTarget(name: "GraphitiTests", dependencies: ["Graphiti"]),
    ]
)
