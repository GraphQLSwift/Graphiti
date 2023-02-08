import Foundation
import Graphiti
import GraphQL
import NIO
import XCTest

final class FederationTests: XCTestCase {
    private var group: MultiThreadedEventLoopGroup!
    private var api: ProductAPI!

    func testProductQuery() throws {
        try XCTAssertEqual(execute(request: query("product"), variables: ["id": "apollo-federation"]), GraphQLResult(data: [
            "product": [
                "id": "apollo-federation",
                "sku": "federation",
                "package": "@apollo/federation",
                "variation": [
                    "id": "OSS"
                ],
                "dimensions": [
                    "size": "small",
                    "weight": 1,
                    "unit":"kg"
                ],
                "createdBy": [
                    "email": "support@apollographql.com",
                    "name": "Jane Smith",
                    "totalProductsCreated": 1337,
                    "yearsOfEmployment": 10,
                    "averageProductsCreatedPerYear": 133
                ],
                "notes": nil,
                "research": [
                    [
                        "study": [
                            "caseNumber": "1234",
                            "description": "Federation Study",
                        ]
                    ]
                ]
            ]
        ]))
    }

    func testProductQueryWithInvalidID() throws {
        try XCTAssertEqual(execute(request: query("product"), variables: ["id": "graphiti"]), GraphQLResult(data: [
            "product": nil
        ]))
    }

    func testDeprecatedProductQuery() throws {
        try XCTAssertEqual(execute(request: query("deprecatedProduct"), variables: ["sku": "apollo-federation-v1", "package": "@apollo/federation-v1"]), GraphQLResult(data: [
            "deprecatedProduct": [
                "sku": "apollo-federation-v1",
                "package": "@apollo/federation-v1",
                "reason": "Migrate to Federation V2",
                "createdBy": [
                    "email": "support@apollographql.com",
                    "name": "Jane Smith",
                    "totalProductsCreated": 1337,
                    "yearsOfEmployment": 10,
                    "averageProductsCreatedPerYear": 133,
                ],
            ]
        ]))
    }

    // Test Queries from https://github.com/apollographql/apollo-federation-subgraph-compatibility/blob/main/COMPATIBILITY.md

    func testServiceQuery() throws {
        try XCTAssertEqual(execute(request: query("service")), GraphQLResult(data: [
            "_service": [
                "sdl": Map(stringLiteral: loadSDL())
            ]
        ]))
    }

    func testEntityKey() throws {
        let representations: [String : Map] = [
            "representations" : [
                [ "__typename": "User", "email": "support@apollographql.com" ]
            ]
        ]

        try XCTAssertEqual(execute(request: query("entities"), variables: representations), GraphQLResult(data: [
            "_entities": [
                [
                    "email": "support@apollographql.com",
                    "name": "Jane Smith",
                    "totalProductsCreated": 1337,
                    "yearsOfEmployment": 10,
                    "averageProductsCreatedPerYear": 133,
                ]
            ]
        ]))
    }

    func testEntityMultipleKey() throws {
        let representations: [String : Map] = [
            "representations" : [
                [ "__typename": "DeprecatedProduct", "sku": "apollo-federation-v1", "package": "@apollo/federation-v1" ]
            ]
        ]

        try XCTAssertEqual(execute(request: query("entities"), variables: representations), GraphQLResult(data: [
            "_entities": [
                [
                    "email": "support@apollographql.com",
                    "name": "Jane Smith",
                    "totalProductsCreated": 1337,
                    "yearsOfEmployment": 10,
                    "averageProductsCreatedPerYear": 133,
                ]
            ]
        ]))
    }

    func testEntityCompositeKey() throws {
        let representations: [String : Map] = [
            "representations" : [
                [ "__typename": "ProductResearch", "study": [ "caseNumber": "1234" ] ]
            ]
        ]

        try XCTAssertEqual(execute(request: query("entities"), variables: representations), GraphQLResult(data: [
            "_entities": [
                [
                    "email": "support@apollographql.com",
                    "name": "Jane Smith",
                    "totalProductsCreated": 1337,
                    "yearsOfEmployment": 10,
                    "averageProductsCreatedPerYear": 133,
                ]
            ]
        ]))
    }

    func testEntityMultipleKeys() throws {
        let representations: [String : Map] = [
            "representations" : [
                [ "__typename": "Product", "id": "apollo-federation" ],
                [ "__typename": "Product", "sku": "federation", "package": "@apollo/federation" ],
                [ "__typename": "Product", "sku": "studio", "variation": [ "id": "platform" ] ],
            ]
        ]

        try XCTAssertEqual(execute(request: query("entities"), variables: representations), GraphQLResult(data: [
            "_entities": [
                [
                    "email": "support@apollographql.com",
                    "name": "Jane Smith",
                    "totalProductsCreated": 1337,
                    "yearsOfEmployment": 10,
                    "averageProductsCreatedPerYear": 133,
                ]
            ]
        ]))
    }
}

// MARK: - Helpers
extension FederationTests {
    enum FederationTestsError: Error {
        case couldNotLoadFile
    }

    func loadSDL() throws -> String {
        guard let url = Bundle.module.url(forResource: "product", withExtension: "graphqls", subdirectory: "GraphQL") else {
            throw FederationTestsError.couldNotLoadFile
        }
        return try String(contentsOf: url)
    }

    func query(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "graphql", subdirectory: "GraphQL") else {
            throw FederationTestsError.couldNotLoadFile
        }
        print(url)
        return try String(contentsOf: url)
    }

    func execute(request: String, variables: [String: Map] = [:]) throws -> GraphQLResult {
        try api.execute(request: request, context: ProductContext(), on: group, variables: variables).wait()
    }

    override func setUp() async throws {
        let schema = try SchemaBuilder(ProductResolver.self, ProductContext.self)
            .use(partials: [ProductSchema()])
//            .enableFederation()
            .build()

        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.api = ProductAPI(resolver: ProductResolver(), schema: schema)
    }

    override func tearDown() async throws {
        try group.syncShutdownGracefully()
        group = nil
        api = nil
    }
}
