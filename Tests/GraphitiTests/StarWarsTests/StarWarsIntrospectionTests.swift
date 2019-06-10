import XCTest
import NIO
import GraphQL

@testable import Graphiti

class StarWarsIntrospectionTests : XCTestCase {
    private let starWarsAPI = StarWarsAPI()
    private let starWarsStore = StarWarsStore()
    
    func testIntrospectionTypeQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionTypeQuery {" +
                    "    __schema {" +
                    "        types {" +
                    "            name" +
                    "        }" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__schema": [
                    "types": [
                        [
                            "name": "Boolean",
                        ],
                        [
                            "name": "Character",
                        ],
                        [
                            "name": "Droid",
                        ],
                        [
                            "name": "Episode",
                        ],
                        [
                            "name": "Human",
                        ],
                        [
                            "name": "Int",
                        ],
                        [
                            "name": "Planet",
                        ],
                        [
                            "name": "Query",
                        ],
                        [
                            "name": "SearchResult",
                        ],
                        [
                            "name": "String",
                        ],
                        [
                            "name": "__Directive",
                        ],
                        [
                            "name": "__DirectiveLocation",
                        ],
                        [
                            "name": "__EnumValue",
                        ],
                        [
                            "name": "__Field",
                        ],
                        [
                            "name": "__InputValue",
                        ],
                        [
                            "name": "__Schema",
                        ],
                        [
                            "name": "__Type",
                        ],
                        [
                            "name": "__TypeKind",
                        ]
                    ]
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionQueryTypeQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionQueryTypeQuery {" +
                    "    __schema {" +
                    "        queryType {" +
                    "            name" +
                    "        }" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__schema": [
                    "queryType": [
                        "name": "Query",
                    ]
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidTypeQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionDroidTypeQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__type": [
                    "name": "Droid",
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidKindQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionDroidKindQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "        kind" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__type": [
                    "name": "Droid",
                    "kind": "OBJECT",
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionCharacterKindQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionCharacterKindQuery {" +
                    "    __type(name: \"Character\") {" +
                    "        name" +
                    "        kind" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__type": [
                    "name": "Character",
                    "kind": "INTERFACE",
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidFieldsQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionDroidFieldsQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "        fields {" +
                    "            name" +
                    "            type {" +
                    "                name" +
                    "                kind" +
                    "            }" +
                    "        }" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__type": [
                    "name": "Droid",
                    "fields": [
                        [
                            "name": "appearsIn",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ]
                        ],
                        [
                            "name": "friends",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ]
                        ],
                        [
                            "name": "id",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ]
                        ],
                        [
                            "name": "name",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ]
                        ],
                        [
                            "name": "primaryFunction",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ]
                        ],
                        [
                            "name": "secretBackstory",
                            "type": [
                                "name": "String",
                                "kind": "SCALAR",
                            ]
                        ]
                    ]
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidNestedFieldsQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionDroidNestedFieldsQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "        fields {" +
                    "            name" +
                    "            type {" +
                    "                name" +
                    "                kind" +
                    "                ofType {" +
                    "                    name" +
                    "                    kind" +
                    "                }" +
                    "            }" +
                    "        }" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__type": [
                    "name": "Droid",
                    "fields": [
                        [
                            "name": "appearsIn",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "kind": "LIST",
                                    "name": nil
                                ]
                            ]
                        ],
                        [
                            "name": "friends",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "kind": "LIST",
                                    "name": nil
                                ]
                            ]
                        ],
                        [
                            "name": "id",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": "String",
                                    "kind": "SCALAR",
                                ]
                            ]
                        ],
                        [
                            "name": "name",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": "String",
                                    "kind": "SCALAR",
                                ]
                            ]
                        ],
                        [
                            "name": "primaryFunction",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": "String",
                                    "kind": "SCALAR",
                                ]
                            ]
                        ],
                        [
                            "name": "secretBackstory",
                            "type": [
                                "name": "String",
                                "kind": "SCALAR",
                                "ofType": nil,
                            ]
                        ]
                    ]
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionFieldArgsQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "query IntrospectionFieldArgsQuery {" +
                    "    __schema {" +
                    "        queryType {" +
                    "            fields {" +
                    "                name" +
                    "                args {" +
                    "                    name" +
                    "                    description" +
                    "                    type {" +
                    "                        name" +
                    "                        kind" +
                    "                        ofType {" +
                    "                            name" +
                    "                            kind" +
                    "                        }" +
                    "                    }" +
                    "                    defaultValue" +
                    "                 }" +
                    "            }" +
                    "        }" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__schema": [
                    "queryType": [
                        "fields": [
                            [
                                "name": "droid",
                                "args": [
                                    [
                                        "name": "id",
                                        "description": "Id of the droid.",
                                        "type": [
                                            "name": nil,
                                            "kind": "NON_NULL",
                                            "ofType": [
                                                "name": "String",
                                                "kind": "SCALAR",
                                            ]
                                        ],
                                        "defaultValue": nil,
                                    ]
                                ]
                            ],
                            [
                                "name": "hero",
                                "args": [
                                    [
                                        "name": "episode",
                                        "description": "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.",
                                        "type": [
                                            "name": "Episode",
                                            "kind": "ENUM",
                                            "ofType": nil
                                        ],
                                        "defaultValue": nil,
                                    ]
                                ]
                            ],
                            [
                                "name": "human",
                                "args": [
                                    [
                                        "name": "id",
                                        "description": "Id of the human.",
                                        "type": [
                                            "name": nil,
                                            "kind": "NON_NULL",
                                            "ofType": [
                                                "name": "String",
                                                "kind": "SCALAR",
                                            ]
                                        ],
                                        "defaultValue": nil,
                                    ]
                                ]
                            ],
                            [
                                "name": "search",
                                "args": [
                                    [
                                        "name": "query",
                                        "description": nil, 
                                        "type": [
                                            "name": nil,
                                            "kind": "NON_NULL",
                                            "ofType": [
                                                "name": "String",
                                                "kind": "SCALAR",
                                            ]
                                        ],
                                        "defaultValue": "R2-D2",
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidDescriptionQuery() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }
        
        let query = "query IntrospectionDroidDescriptionQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "        description" +
                    "    }" +
                    "}"

        let expected = GraphQLResult(
            data: [
                "__type": [
                    "name": "Droid",
                    "description": "A mechanical creature in the Star Wars universe.",
                ],
            ]
        )

        let result = try starWarsSchema.execute(
            request: query,
            root: self.starWarsAPI,
            context: self.starWarsStore,
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }
}

extension StarWarsIntrospectionTests {
    static var allTests: [(String, (StarWarsIntrospectionTests) -> () throws -> Void)] {
        return [
            ("testIntrospectionTypeQuery", testIntrospectionTypeQuery),
            ("testIntrospectionQueryTypeQuery", testIntrospectionQueryTypeQuery),
            ("testIntrospectionDroidTypeQuery", testIntrospectionDroidTypeQuery),
            ("testIntrospectionDroidKindQuery", testIntrospectionDroidKindQuery),
            ("testIntrospectionCharacterKindQuery", testIntrospectionCharacterKindQuery),
            ("testIntrospectionDroidFieldsQuery", testIntrospectionDroidFieldsQuery),
            ("testIntrospectionDroidNestedFieldsQuery", testIntrospectionDroidNestedFieldsQuery),
            ("testIntrospectionFieldArgsQuery", testIntrospectionFieldArgsQuery),
            ("testIntrospectionDroidDescriptionQuery", testIntrospectionDroidDescriptionQuery),
        ]
    }
}
