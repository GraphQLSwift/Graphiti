import XCTest
import NIO
@testable import Graphiti
import GraphQL

@available(OSX 10.15, *)
class StarWarsQueryTests : XCTestCase {
    private let api = StarWarsAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
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
        let expectation = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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

        let expectation = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        var expectation: XCTestExpectation

        params = ["someId": "1000"]

        expected = GraphQLResult(
            data: [
                "human": [
                    "name": "Luke Skywalker",
                ],
            ]
        )
        
        expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group,
            variables: params
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)

        params = ["someId": "1002"]

        expected = GraphQLResult(
            data: [
                "human": [
                    "name": "Han Solo",
                ],
            ]
        )
        
        expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group,
            variables: params
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)

        params = ["someId": "not a valid id"]

        expected = GraphQLResult(
            data: [
                "human": nil,
            ]
        )
        
        expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group,
            variables: params
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        struct MyAPI : API {
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
        
        let expectation = XCTestExpectation()
        let api = MyAPI()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testDirective() throws {
        var query: String
        var expected: GraphQLResult
        var expectation: XCTestExpectation
        
        query = """
        query Hero {
            hero {
                name

                friends @include(if: false) {
                    name
                }
            }
        }
        """

        expected = GraphQLResult(
            data: [
                "hero": [
                    "name": "R2-D2",
                ],
            ]
        )
        
        expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
        
        query = """
        query Hero {
            hero {
                name

                friends @include(if: true) {
                    name
                }
            }
        }
        """

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
        
        expectation = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
