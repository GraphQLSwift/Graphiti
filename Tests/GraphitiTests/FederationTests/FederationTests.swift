import Foundation
import Graphiti
import GraphQL
import Testing

struct FederationTests {
    private var api: ProductAPI

    init() throws {
        let sdl = try Self.loadSDL()
        let schema = try SchemaBuilder(ProductResolver.self, ProductContext.self)
            .use(partials: [ProductSchema()])
            .setFederatedSDL(to: sdl)
            .build()
        api = ProductAPI(resolver: ProductResolver(sdl: sdl), schema: schema)
    }

    // Test Queries from https://github.com/apollographql/apollo-federation-subgraph-compatibility/blob/main/COMPATIBILITY.md

    @Test func serviceQuery() async throws {
        let result = try await execute(request: Self.query("service"))
        let sdl = try Self.loadSDL()
        #expect(
            result ==
                GraphQLResult(data: [
                    "_service": [
                        "sdl": Map(stringLiteral: sdl),
                    ],
                ])
        )
    }

    @Test func entityKey() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "User", "email": "support@apollographql.com"],
            ],
        ]

        let result = try await execute(request: Self.query("entities"), variables: representations)
        #expect(
            result ==
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

    @Test func entityMultipleKey() async throws {
        let representations: [String: Map] = [
            "representations": [
                [
                    "__typename": "DeprecatedProduct",
                    "sku": "apollo-federation-v1",
                    "package": "@apollo/federation-v1",
                ],
            ],
        ]

        let result = try await execute(request: Self.query("entities"), variables: representations)
        #expect(
            result ==
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

    @Test func entityCompositeKey() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "ProductResearch", "study": ["caseNumber": "1234"]],
            ],
        ]

        let result = try await execute(request: Self.query("entities"), variables: representations)
        #expect(
            result ==
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

    @Test func entityMultipleKeys() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "Product", "id": "apollo-federation"],
                ["__typename": "Product", "sku": "federation", "package": "@apollo/federation"],
                ["__typename": "Product", "sku": "studio", "variation": ["id": "platform"]],
            ],
        ]

        let result = try await execute(request: Self.query("entities"), variables: representations)
        #expect(
            result ==
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

    static func loadSDL() throws -> String {
        guard
            let url = Bundle.module.url(
                forResource: "product",
                withExtension: "graphqls",
                subdirectory: "GraphQL"
            )
        else {
            throw FederationTestsError.couldNotLoadFile
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    static func query(_ name: String) throws -> String {
        guard
            let url = Bundle.module.url(
                forResource: name,
                withExtension: "graphql",
                subdirectory: "GraphQL"
            )
        else {
            throw FederationTestsError.couldNotLoadFile
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    func execute(request: String, variables: [String: Map] = [:]) async throws -> GraphQLResult {
        try await api.execute(request: request, context: ProductContext(), variables: variables)
    }
}
