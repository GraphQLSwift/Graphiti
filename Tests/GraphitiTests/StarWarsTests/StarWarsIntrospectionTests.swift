import XCTest
import NIO
import GraphQL

@testable import Graphiti

class StarWarsIntrospectionTests : XCTestCase {
    private let api = StarWarsAPI()
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    deinit {
        try? group.syncShutdownGracefully()
    }
    
    func testIntrospectionTypeQuery() throws {
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionQueryTypeQuery() throws {
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionDroidTypeQuery() throws {
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionDroidKindQuery() throws {
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionCharacterKindQuery() throws {
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionDroidFieldsQuery() throws {
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionDroidNestedFieldsQuery() throws {
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
                                    "name": nil,
                                    "kind": "LIST"
                                ]
                            ]
                        ],
                        [
                            "name": "friends",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": nil,
                                    "kind": "LIST"
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
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionFieldArgsQuery() throws {
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
                                        "defaultValue": "\"R2-D2\"",
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        )
        
        let expectation = XCTestExpectation()

        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    func testIntrospectionDroidDescriptionQuery() throws {
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

        let expectation = XCTestExpectation()
        
        api.execute(
            request: query,
            context: StarWarsContext(),
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
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
