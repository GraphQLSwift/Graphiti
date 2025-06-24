import Foundation
import Graphiti
import GraphQL
import XCTest

final class FederationTests: XCTestCase {
    private var api: ProductAPI!

    override func setUpWithError() throws {
        let schema = try SchemaBuilder(ProductResolver.self, ProductContext.self)
            .use(partials: [ProductSchema()])
            .setFederatedSDL(to: loadSDL())
            .build()
        api = try ProductAPI(resolver: ProductResolver(sdl: loadSDL()), schema: schema)
    }

    override func tearDownWithError() throws {
        api = nil
    }

    // Test Queries from https://github.com/apollographql/apollo-federation-subgraph-compatibility/blob/main/COMPATIBILITY.md

    func testServiceQuery() async throws {
        let result = try await execute(request: query("service"))
        try XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_service": [
                    "sdl": Map(stringLiteral: loadSDL()),
                ],
            ])
        )
    }

    func testEntityKey() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "User", "email": "support@apollographql.com"],
            ],
        ]

        let result = try await execute(request: query("entities"), variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
                        "email": "support@apollographql.com",
                        "name": "Jane Smith",
                        "totalProductsCreated": 1337,
                        "yearsOfEmployment": 10,
                        "averageProductsCreatedPerYear": 133,
                    ],
                ],
            ])
        )
    }

    func testEntityMultipleKey() async throws {
        let representations: [String: Map] = [
            "representations": [
                [
                    "__typename": "DeprecatedProduct",
                    "sku": "apollo-federation-v1",
                    "package": "@apollo/federation-v1",
                ],
            ],
        ]

        let result = try await execute(request: query("entities"), variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
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
                    ],
                ],
            ])
        )
    }

    func testEntityCompositeKey() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "ProductResearch", "study": ["caseNumber": "1234"]],
            ],
        ]

        let result = try await execute(request: query("entities"), variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
                        "study": [
                            "caseNumber": "1234",
                            "description": "Federation Study",
                        ],
                        "outcome": nil,
                    ],
                ],
            ])
        )
    }

    func testEntityMultipleKeys() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "Product", "id": "apollo-federation"],
                ["__typename": "Product", "sku": "federation", "package": "@apollo/federation"],
                ["__typename": "Product", "sku": "studio", "variation": ["id": "platform"]],
            ],
        ]

        let result = try await execute(request: query("entities"), variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
                        "id": "apollo-federation",
                        "sku": "federation",
                        "package": "@apollo/federation",
                        "variation": [
                            "id": "OSS",
                        ],
                        "dimensions": [
                            "size": "small",
                            "unit": "kg",
                            "weight": 1,
                        ],
                        "createdBy": [
                            "email": "support@apollographql.com",
                            "name": "Jane Smith",
                            "totalProductsCreated": 1337,
                            "yearsOfEmployment": 10,
                            "averageProductsCreatedPerYear": 133,
                        ],
                        "notes": nil,
                        "research": [
                            [
                                "outcome": nil,
                                "study": [
                                    "caseNumber": "1234",
                                    "description": "Federation Study",
                                ],
                            ],
                        ],
                    ],
                    [
                        "id": "apollo-federation",
                        "sku": "federation",
                        "package": "@apollo/federation",
                        "variation": [
                            "id": "OSS",
                        ],
                        "dimensions": [
                            "size": "small",
                            "unit": "kg",
                            "weight": 1,
                        ],
                        "createdBy": [
                            "email": "support@apollographql.com",
                            "name": "Jane Smith",
                            "totalProductsCreated": 1337,
                            "yearsOfEmployment": 10,
                            "averageProductsCreatedPerYear": 133,
                        ],
                        "notes": nil,
                        "research": [
                            [
                                "outcome": nil,
                                "study": [
                                    "caseNumber": "1234",
                                    "description": "Federation Study",
                                ],
                            ],
                        ],
                    ],
                    [
                        "id": "apollo-studio",
                        "sku": "studio",
                        "package": "",
                        "variation": [
                            "id": "platform",
                        ],
                        "dimensions": [
                            "size": "small",
                            "unit": "kg",
                            "weight": 1,
                        ],
                        "createdBy": [
                            "email": "support@apollographql.com",
                            "name": "Jane Smith",
                            "totalProductsCreated": 1337,
                            "yearsOfEmployment": 10,
                            "averageProductsCreatedPerYear": 133,
                        ],
                        "notes": nil,
                        "research": [
                            [
                                "outcome": nil,
                                "study": [
                                    "caseNumber": "1235",
                                    "description": "Studio Study",
                                ],
                            ],
                        ],
                    ],
                ],
            ])
        )
    }
}

// MARK: - Helpers

extension FederationTests {
    enum FederationTestsError: Error {
        case couldNotLoadFile
    }

    func loadSDL() throws -> String {
        guard
            let url = Bundle.module.url(
                forResource: "product",
                withExtension: "graphqls",
                subdirectory: "GraphQL"
            )
        else {
            throw FederationTestsError.couldNotLoadFile
        }
        return try String(contentsOf: url)
    }

    func query(_ name: String) throws -> String {
        guard
            let url = Bundle.module.url(
                forResource: name,
                withExtension: "graphql",
                subdirectory: "GraphQL"
            )
        else {
            throw FederationTestsError.couldNotLoadFile
        }
        return try String(contentsOf: url)
    }

    func execute(request: String, variables: [String: Map] = [:]) async throws -> GraphQLResult {
        try await api.execute(request: request, context: ProductContext(), variables: variables)
    }
}
