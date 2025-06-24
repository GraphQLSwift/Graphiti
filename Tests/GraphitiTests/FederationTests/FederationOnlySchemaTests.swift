import Foundation
import Graphiti
import GraphQL
import XCTest

final class FederationOnlySchemaTests: XCTestCase {
    private var api: FederationOnlyAPI!

    struct Profile: Codable {
        let name: String
        let email: String?
    }

    struct User: Codable {
        let id: String

        func profile(context _: NoContext, args _: NoArguments) async throws -> Profile {
            if id == "1" {
                return Profile(name: "User \(id)", email: nil)
            } else {
                return Profile(name: "User \(id)", email: "\(id)@example.com")
            }
        }

        struct Key: Codable {
            let id: String
        }
    }

    struct FederationOnlyResolver {
        func user(context _: NoContext, key: User.Key) async throws -> User {
            User(id: key.id)
        }
    }

    struct FederationOnlyAPI: API {
        var resolver: FederationOnlyResolver
        var schema: Schema<FederationOnlyResolver, NoContext>
    }

    static let federatedSDL: String =
        """
        type User @key(fields: "id") {
            id: String!
            profile: Profile!
        }

        type Profile {
            name: String!
            email: String
        }
        """

    override func setUpWithError() throws {
        let schema = try SchemaBuilder(FederationOnlyResolver.self, NoContext.self)
            .setFederatedSDL(to: Self.federatedSDL)
            .add {
                Type(User.self) {
                    Field("id", at: \.id)
                    Field("profile", at: User.profile)
                }
                .key(at: FederationOnlyResolver.user) {
                    Argument("id", at: \.id)
                }

                Type(Profile.self) {
                    Field("name", at: \.name)
                    Field("email", at: \.email)
                }
            }
            .build()
        api = FederationOnlyAPI(resolver: FederationOnlyResolver(), schema: schema)
    }

    override func tearDownWithError() throws {
        api = nil
    }

    func execute(request: String, variables: [String: Map] = [:]) async throws -> GraphQLResult {
        try await api.execute(
            request: request,
            context: NoContext(),
            variables: variables
        )
    }

    func testUserFederationSimple() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "User", "id": "1234"],
            ],
        ]

        let query =
            """
            query user($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on User {
                  id
                }
              }
            }
            """

        let result = try await execute(request: query, variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
                        "id": "1234",
                    ],
                ],
            ])
        )
    }

    func testUserFederationNested() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "User", "id": "1234"],
            ],
        ]

        let query =
            """
            query user($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on User {
                  id
                  profile { name, email }
                }
              }
            }
            """

        let result = try await execute(request: query, variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
                        "id": "1234",
                        "profile": [
                            "name": "User 1234",
                            "email": "1234@example.com",
                        ],
                    ],
                ],
            ])
        )
    }

    func testUserFederationNestedOptional() async throws {
        let representations: [String: Map] = [
            "representations": [
                ["__typename": "User", "id": "1"],
            ],
        ]

        let query =
            """
            query user($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on User {
                  id
                  profile { name, email }
                }
              }
            }
            """

        let result = try await execute(request: query, variables: representations)
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "_entities": [
                    [
                        "id": "1",
                        "profile": [
                            "name": "User 1",
                            "email": .null,
                        ],
                    ],
                ],
            ])
        )
    }
}
