@testable import Graphiti
import GraphQL
import NIO
import XCTest

class StarWarsQueryTests: XCTestCase {
    private let api = StarWarsAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? self.group.syncShutdownGracefully()
    }

    func testHeroNameQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query HeroNameQuery {
                    hero {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(data: ["hero": ["name": "R2-D2"]])
        )
    }

    func testHeroNameAndFriendsQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query HeroNameAndFriendsQuery {
                    hero {
                        id
                        name
                        friends {
                            name
                        }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "id": "2001",
                        "name": "R2-D2",
                        "friends": [
                            ["name": "Luke Skywalker"],
                            ["name": "Han Solo"],
                            ["name": "Leia Organa"],
                        ],
                    ],
                ]
            )
        )
    }

    func testNestedQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query NestedQuery {
                    hero {
                        name
                        friends {
                            name
                            appearsIn
                            friends {
                                name
                            }
                        }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "name": "R2-D2",
                        "friends": [
                            [
                                "name": "Luke Skywalker",
                                "appearsIn": ["NEWHOPE", "EMPIRE", "JEDI"],
                                "friends": [
                                    ["name": "Han Solo"],
                                    ["name": "Leia Organa"],
                                    ["name": "C-3PO"],
                                    ["name": "R2-D2"],
                                ],
                            ],
                            [
                                "name": "Han Solo",
                                "appearsIn": ["NEWHOPE", "EMPIRE", "JEDI"],
                                "friends": [
                                    ["name": "Luke Skywalker"],
                                    ["name": "Leia Organa"],
                                    ["name": "R2-D2"],
                                ],
                            ],
                            [
                                "name": "Leia Organa",
                                "appearsIn": ["NEWHOPE", "EMPIRE", "JEDI"],
                                "friends": [
                                    ["name": "Luke Skywalker"],
                                    ["name": "Han Solo"],
                                    ["name": "C-3PO"],
                                    ["name": "R2-D2"],
                                ],
                            ],
                        ],
                    ],
                ]
            )
        )
    }

    func testFetchLukeQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query FetchLukeQuery {
                    human(id: "1000") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "human": [
                        "name": "Luke Skywalker",
                    ],
                ]
            )
        )
    }

    func testFetchSomeIDQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query FetchSomeIDQuery($someId: String!) {
                    human(id: $someId) {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group,
                variables: ["someId": "1000"]
            ).wait(),
            GraphQLResult(
                data: [
                    "human": [
                        "name": "Luke Skywalker",
                    ],
                ]
            )
        )

        XCTAssertEqual(
            try api.execute(
                request: """
                query FetchSomeIDQuery($someId: String!) {
                    human(id: $someId) {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group,
                variables: ["someId": "1002"]
            ).wait(),
            GraphQLResult(
                data: [
                    "human": [
                        "name": "Han Solo",
                    ],
                ]
            )
        )

        XCTAssertEqual(
            try api.execute(
                request: """
                query FetchSomeIDQuery($someId: String!) {
                    human(id: $someId) {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group,
                variables: ["someId": "not a valid id"]
            ).wait(),
            GraphQLResult(
                data: [
                    "human": nil,
                ]
            )
        )
    }

    func testFetchLukeAliasedQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query FetchLukeAliasedQuery {
                    luke: human(id: "1000") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "luke": [
                        "name": "Luke Skywalker",
                    ],
                ]
            )
        )
    }

    func testFetchLukeAndLeiaAliasedQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query FetchLukeAndLeiaAliasedQuery {
                    luke: human(id: "1000") {
                        name
                    }
                    leia: human(id: "1003") {
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "luke": [
                        "name": "Luke Skywalker",
                    ],
                    "leia": [
                        "name": "Leia Organa",
                    ],
                ]
            )
        )
    }

    func testDuplicateFieldsQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query DuplicateFieldsQuery {
                    luke: human(id: "1000") {
                        name
                        homePlanet { name }
                    }
                    leia: human(id: "1003") {
                        name
                        homePlanet  { name }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "luke": [
                        "name": "Luke Skywalker",
                        "homePlanet": ["name": "Tatooine"],
                    ],
                    "leia": [
                        "name": "Leia Organa",
                        "homePlanet": ["name": "Alderaan"],
                    ],
                ]
            )
        )
    }

    func testUseFragmentQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query UseFragmentQuery {
                    luke: human(id: "1000") {
                        ...HumanFragment
                    }
                    leia: human(id: "1003") {
                        ...HumanFragment
                    }
                }
                fragment HumanFragment on Human {
                    name
                    homePlanet { name }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "luke": [
                        "name": "Luke Skywalker",
                        "homePlanet": ["name": "Tatooine"],
                    ],
                    "leia": [
                        "name": "Leia Organa",
                        "homePlanet": ["name": "Alderaan"],
                    ],
                ]
            )
        )
    }

    func testCheckTypeOfR2Query() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query CheckTypeOfR2Query {
                    hero {
                        __typename
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "__typename": "Droid",
                        "name": "R2-D2",
                    ],
                ]
            )
        )
    }

    func testCheckTypeOfLukeQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query CheckTypeOfLukeQuery {
                    hero(episode: EMPIRE) {
                        __typename
                        name
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "__typename": "Human",
                        "name": "Luke Skywalker",
                    ],
                ]
            )
        )
    }

    func testSecretBackstoryQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query SecretBackstoryQuery {
                    hero {
                        name
                        secretBackstory
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "name": "R2-D2",
                        "secretBackstory": nil,
                    ],
                ],
                errors: [
                    GraphQLError(
                        message: "secretBackstory is secret.",
                        locations: [SourceLocation(line: 4, column: 9)],
                        path: ["hero", "secretBackstory"]
                    ),
                ]
            )
        )
    }

    func testSecretBackstoryListQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query SecretBackstoryListQuery {
                    hero {
                        name
                        friends {
                            name
                            secretBackstory
                        }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "name": "R2-D2",
                        "friends": [
                            [
                                "name": "Luke Skywalker",
                                "secretBackstory": nil,
                            ],
                            [
                                "name": "Han Solo",
                                "secretBackstory": nil,
                            ],
                            [
                                "name": "Leia Organa",
                                "secretBackstory": nil,
                            ],
                        ],
                    ],
                ],
                errors: [
                    GraphQLError(
                        message: "secretBackstory is secret.",
                        locations: [SourceLocation(line: 6, column: 13)],
                        path: ["hero", "friends", 0, "secretBackstory"]
                    ),
                    GraphQLError(
                        message: "secretBackstory is secret.",
                        locations: [SourceLocation(line: 6, column: 13)],
                        path: ["hero", "friends", 1, "secretBackstory"]
                    ),
                    GraphQLError(
                        message: "secretBackstory is secret.",
                        locations: [SourceLocation(line: 6, column: 13)],
                        path: ["hero", "friends", 2, "secretBackstory"]
                    ),
                ]
            )
        )
    }

    func testSecretBackstoryAliasQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query SecretBackstoryAliasQuery {
                    mainHero: hero {
                        name
                        story: secretBackstory
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "mainHero": [
                        "name": "R2-D2",
                        "story": nil,
                    ],
                ],
                errors: [
                    GraphQLError(
                        message: "secretBackstory is secret.",
                        locations: [SourceLocation(line: 4, column: 9)],
                        path: ["mainHero", "story"]
                    ),
                ]
            )
        )
    }

    func testNonNullableFieldsQuery() throws {
        struct A {
            func nullableA(context _: NoContext, arguments _: NoArguments) -> A? {
                return A()
            }

            func nonNullA(context _: NoContext, arguments _: NoArguments) -> A {
                return A()
            }

            func `throws`(context _: NoContext, arguments _: NoArguments) throws -> String {
                struct 🏃: Error, CustomStringConvertible {
                    let description: String
                }

                throw 🏃(description: "catch me if you can.")
            }
        }

        struct TestResolver {
            func nullableA(context _: NoContext, arguments _: NoArguments) -> A? {
                return A()
            }
        }

        struct MyAPI: API {
            var resolver: TestResolver = .init()

            let schema = try! Schema<TestResolver, NoContext> {
                Type(A.self) {
                    Field("nullableA", at: A.nullableA)
                    Field("nonNullA", at: A.nonNullA)
                    Field("throws", at: A.throws)
                }

                Query {
                    Field("nullableA", at: TestResolver.nullableA)
                }
            }
        }
        let api = MyAPI()

        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                    nullableA {
                        nullableA {
                            nonNullA {
                                nonNullA {
                                    throws
                                }
                            }
                        }
                    }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "nullableA": [
                        "nullableA": nil,
                    ],
                ],
                errors: [
                    GraphQLError(
                        message: "catch me if you can.",
                        locations: [SourceLocation(line: 6, column: 21)],
                        path: ["nullableA", "nullableA", "nonNullA", "nonNullA", "throws"]
                    ),
                ]
            )
        )
    }

    func testSearchQuery() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query {
                    search(query: "o") {
                        ... on Planet {
                            name
                            diameter
                        }
                        ... on Human {
                            name
                        }
                        ... on Droid {
                            name
                            primaryFunction
                        }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "search": [
                        ["name": "Tatooine", "diameter": 10465],
                        ["name": "Han Solo"],
                        ["name": "Leia Organa"],
                        ["name": "C-3PO", "primaryFunction": "Protocol"],
                    ],
                ]
            )
        )
    }

    func testDirective() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query Hero {
                    hero {
                        name

                        friends @include(if: false) {
                            name
                        }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "name": "R2-D2",
                    ],
                ]
            )
        )

        XCTAssertEqual(
            try api.execute(
                request: """
                query Hero {
                    hero {
                        name

                        friends @include(if: true) {
                            name
                        }
                    }
                }
                """,
                context: StarWarsContext(),
                on: group
            ).wait(),
            GraphQLResult(
                data: [
                    "hero": [
                        "name": "R2-D2",
                        "friends": [
                            ["name": "Luke Skywalker"],
                            ["name": "Han Solo"],
                            ["name": "Leia Organa"],
                        ],
                    ],
                ]
            )
        )
    }
}
