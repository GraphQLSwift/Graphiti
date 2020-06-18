import XCTest
import NIO
@testable import Graphiti
import GraphQL
import StarWarsAPI
import Combine

@available(OSX 10.15, *)
class StarWarsQueryTests : XCTestCase {
    private let service = StarWarsService()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    deinit {
        try? self.group.syncShutdownGracefully()
    }
    
    func testHeroNameQuery() throws {
        let query = """
        query HeroNameQuery {
            hero {
                name
            }
        }
        """
        
        let expected = GraphQLResult(data: ["hero": ["name": "R2-D2"]])
        
        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testHeroNameAndFriendsQuery() throws {
        let query = """
        query HeroNameAndFriendsQuery {
            hero {
                id
                name
                friends {
                    name
                }
            }
        }
        """

        let expected = GraphQLResult(
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

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testNestedQuery() throws {
        let query = """
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
        """

        let expected = GraphQLResult(
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

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testFetchLukeQuery() throws {
        let query = """
        query FetchLukeQuery {
            human(id: "1000") {
                name
            }
        }
        """

        let expected = GraphQLResult(
            data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testFetchSomeIDQuery() throws {
        let query = """
        query FetchSomeIDQuery($someId: String!) {
            human(id: $someId) {
                name
            }
        }
        """

        var params: [String: Map]
        var expected: GraphQLResult
        var result: GraphQLResult

        params = ["someId": "1000"]

        expected = GraphQLResult(
            data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ]
        )

        result = try service.execute(
            request: query,
            on: group,
            variables: params
        ).wait()
        
        XCTAssertEqual(result, expected)

        params = ["someId": "1002"]

        expected = GraphQLResult(
            data: [
                "human": [
                    "name": "Han Solo",
                ],
            ]
        )

        result = try service.execute(
            request: query,
            on: group,
            variables: params
        ).wait()
        
        XCTAssertEqual(result, expected)

        params = ["someId": "not a valid id"]

        expected = GraphQLResult(
            data: [
                "human": nil,
            ]
        )

        result = try service.execute(
            request: query,
            on: group,
            variables: params
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testFetchLukeAliasedQuery() throws {
        let query = """
        query FetchLukeAliasedQuery {
            luke: human(id: "1000") {
                name
            }
        }
        """

        let expected = GraphQLResult(
            data: [
                "luke": [
                    "name": "Luke Skywalker",
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testFetchLukeAndLeiaAliasedQuery() throws {
        let query = """
        query FetchLukeAndLeiaAliasedQuery {
            luke: human(id: "1000") {
                name
            }
            leia: human(id: "1003") {
                name
            }
        }
        """

        let expected = GraphQLResult(
            data: [
                "luke": [
                    "name": "Luke Skywalker",
                ],
                "leia": [
                    "name": "Leia Organa",
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testDuplicateFieldsQuery() throws {
        let query = """
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
        """

        let expected = GraphQLResult(
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

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testUseFragmentQuery() throws {
        let query = """
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
        """

        let expected = GraphQLResult(
            data: [
                "luke": [
                    "name": "Luke Skywalker",
                    "homePlanet": ["name":"Tatooine"],
                ],
                "leia": [
                    "name": "Leia Organa",
                    "homePlanet": ["name":"Alderaan"],
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testCheckTypeOfR2Query() throws {
        let query = """
        query CheckTypeOfR2Query {
            hero {
                __typename
                name
            }
        }
        """

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "__typename": "Droid",
                    "name": "R2-D2",
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testCheckTypeOfLukeQuery() throws {
        let query = """
        query CheckTypeOfLukeQuery {
            hero(episode: EMPIRE) {
                __typename
                name
            }
        }
        """
        
        let expected = GraphQLResult(
            data: [
                "hero": [
                    "__typename": "Human",
                    "name": "Luke Skywalker",
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testSecretBackstoryQuery() throws {
        let query = """
        query SecretBackstoryQuery {
            hero {
                name
                secretBackstory
            }
        }
        """

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "name": "R2-D2",
                    "secretBackstory": nil,
                ]
            ],
            errors: [
                GraphQLError(
                    message: "secretBackstory is secret.",
                    locations: [SourceLocation(line: 4, column: 9)],
                    path: ["hero", "secretBackstory"]
                )
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testSecretBackstoryListQuery() throws {
        let query = """
        query SecretBackstoryListQuery {
            hero {
                name
                friends {
                    name
                    secretBackstory
                }
            }
        }
        """
        
        let expected = GraphQLResult(
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
                        ]
                    ]
                ]
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
                )
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()

        XCTAssertEqual(result, expected)
    }

    func testSecretBackstoryAliasQuery() throws {
        let query = """
        query SecretBackstoryAliasQuery {
            mainHero: hero {
                name
                story: secretBackstory
            }
        }
        """

        let expected = GraphQLResult(
            data: [
                "mainHero": [
                    "name": "R2-D2",
                    "story": nil,
                ]
            ],
            errors: [
                GraphQLError(
                    message: "secretBackstory is secret.",
                    locations: [SourceLocation(line: 4, column: 9)],
                    path: ["mainHero", "story"]
                )
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()

        XCTAssertEqual(result, expected)
    }

    func testNonNullableFieldsQuery() throws {
        struct A : Codable, Keyable {
            enum Keys : String {
                case nullableA
                case nonNullA
                case `throws`
            }

            func nullableA(context: NoContext, arguments: NoArguments) -> A? {
                return A()
            }

            func nonNullA(context: NoContext, arguments: NoArguments) -> A {
                return A()
            }

            func `throws`(context: NoContext, arguments: NoArguments) throws -> String {
                struct 🏃 : Error, CustomStringConvertible {
                    let description: String
                }

                throw 🏃(description: "catch me if you can.")
            }
        }

        struct Root : Keyable {
            enum Keys : String {
                case nullableA
            }

            func nullableA(context: NoContext, arguments: NoArguments) -> A? {
                return A()
            }
        }
        
        struct MyService : Service {
            var root: Root = Root()
            var context: NoContext = NoContext()
            
            let schema = try! Schema<Root, NoContext> { schema in
                schema.type(A.self) { type in
                    type.field(.nullableA, at: A.nullableA, overridingType: (TypeReference<A>?).self)
                    type.field(.nonNullA, at: A.nonNullA, overridingType: TypeReference<A>.self)
                    type.field(.throws, at: A.throws)
                }

                schema.query { query in
                    query.field(.nullableA, at: Root.nullableA)
                }
            }
        }

        let query = """
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
        """

        let expected = GraphQLResult(
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
        
        let service = MyService()

        let result = try service.execute(
            request: query,
            on: group
        ).wait()

        XCTAssertEqual(result, expected)
    }

    func testSearchQuery() throws {
        let query = """
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
        """

        let expected = GraphQLResult(
            data: [
                "search": [
                    [ "name": "Tatooine", "diameter": 10465 ],
                    [ "name": "Han Solo" ],
                    [ "name": "Leia Organa" ],
                    [ "name": "C-3PO", "primaryFunction": "Protocol" ],
                ],
            ]
        )

        let result = try service.execute(
            request: query,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testDirective() throws {
        struct HeroQueryVariables : Encodable, Keyable {
            enum Keys : String {
                case episode
                case includeFriends
            }

            let episode: Episode
            let includeFriends: Bool
        }

        let query = """
        query Hero($episode: Episode, $includeFriends: Boolean!) {
            hero {
                name

                friends @include(if: $includeFriends) {
                    name
                }
            }
        }
        """

        var variables: [String: Map]
        var result: GraphQLResult
        var expected: GraphQLResult

        expected = GraphQLResult(
            data: [
                "hero": [
                    "name": "R2-D2",
                ],
            ]
        )

        variables = ["episode": "JEDI", "includeFriends": false]

        result = try service.execute(
            request: query,
            on: group,
            variables: variables
        ).wait()
        
        XCTAssertEqual(result, expected)

        variables = ["episode": "JEDI", "includeFriends": true]

        expected = GraphQLResult(
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
        
        result = try service.execute(
            request: query,
            on: group,
            variables: variables
        ).wait()

        XCTAssertEqual(result, expected)
    }
}

@available(OSX 10.15, *)
extension StarWarsQueryTests {
    static var allTests: [(String, (StarWarsQueryTests) -> () throws -> Void)] {
        return [
            ("testHeroNameQuery", testHeroNameQuery),
            ("testHeroNameAndFriendsQuery", testHeroNameAndFriendsQuery),
            ("testNestedQuery", testNestedQuery),
            ("testFetchLukeQuery", testFetchLukeQuery),
            ("testFetchSomeIDQuery", testFetchSomeIDQuery),
            ("testFetchLukeAliasedQuery", testFetchLukeAliasedQuery),
            ("testFetchLukeAndLeiaAliasedQuery", testFetchLukeAndLeiaAliasedQuery),
            ("testDuplicateFieldsQuery", testDuplicateFieldsQuery),
            ("testUseFragmentQuery", testUseFragmentQuery),
            ("testCheckTypeOfR2Query", testCheckTypeOfR2Query),
            ("testCheckTypeOfLukeQuery", testCheckTypeOfLukeQuery),
            ("testSecretBackstoryQuery", testSecretBackstoryQuery),
            ("testSecretBackstoryListQuery", testSecretBackstoryListQuery),
            ("testNonNullableFieldsQuery", testNonNullableFieldsQuery),
            ("testSearchQuery", testSearchQuery),
            ("testDirective", testDirective),
        ]
    }
}
