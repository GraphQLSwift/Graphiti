import XCTest
@testable import Graphiti

class StarWarsIntrospectionTests : XCTestCase {
    func testIntrospectionTypeQuery() throws {
        let query = "query IntrospectionTypeQuery {" +
                    "    __schema {" +
                    "        types {" +
                    "            name" +
                    "        }" +
                    "    }" +
                    "}"

        #if os(macOS)
        let expected: Map = [
            "data": [
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
                            "name": "Query",
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
                        ],
                    ],
                ],
            ],
        ]
        #else
        let expected: Map = [
            "data": [
                "__schema": [
                    "types": [
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
                        ],
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
                            "name": "Query",
                        ],
                        [
                            "name": "String",
                        ],
                    ],
                ],
            ],
        ]
        #endif

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionQueryTypeQuery() throws {
        let query = "query IntrospectionQueryTypeQuery {" +
                    "    __schema {" +
                    "        queryType {" +
                    "            name" +
                    "        }" +
                    "    }" +
                    "}"

        let expected: Map = [
            "data": [
                "__schema": [
                    "queryType": [
                        "name": "Query",
                    ],
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidTypeQuery() throws {
        let query = "query IntrospectionDroidTypeQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "    }" +
                    "}"

        let expected: Map = [
            "data": [
                "__type": [
                    "name": "Droid",
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidKindQuery() throws {
        let query = "query IntrospectionDroidKindQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "        kind" +
                    "    }" +
                    "}"

        let expected: Map = [
            "data": [
                "__type": [
                    "name": "Droid",
                    "kind": "OBJECT",
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionCharacterKindQuery() throws {
        let query = "query IntrospectionCharacterKindQuery {" +
                    "    __type(name: \"Character\") {" +
                    "        name" +
                    "        kind" +
                    "    }" +
                    "}"

        let expected: Map = [
            "data": [
                "__type": [
                    "name": "Character",
                    "kind": "INTERFACE",
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
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

        let expected: Map = [
            "data": [
                "__type": [
                    "name": "Droid",
                    "fields": [
                        [
                            "name": "appearsIn",
                            "type": [
                                "name": nil,
                                "kind": "LIST",
                            ],
                        ],
                        [
                            "name": "friends",
                            "type": [
                                "name": nil,
                                "kind": "LIST",
                            ],
                        ],
                        [
                            "name": "id",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ],
                        ],
                        [
                            "name": "name",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ],
                        ],
                        [
                            "name": "primaryFunction",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                            ],
                        ],
                        [
                            "name": "secretBackstory",
                            "type": [
                                "name": "String",
                                "kind": "SCALAR",
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
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

        let expected: Map = [
            "data": [
                "__type": [
                    "name": "Droid",
                    "fields": [
                        [
                            "name": "appearsIn",
                            "type": [
                                "name": nil,
                                "kind": "LIST",
                                "ofType": [
                                    "kind": "NON_NULL",
                                    "name": nil
                                ]
                            ],
                        ],
                        [
                            "name": "friends",
                            "type": [
                                "name": nil,
                                "kind": "LIST",
                                "ofType": [
                                    "kind": "NON_NULL",
                                    "name": nil
                                ]
                            ],
                        ],
                        [
                            "name": "id",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": "String",
                                    "kind": "SCALAR",
                                ],
                            ],
                        ],
                        [
                            "name": "name",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": "String",
                                    "kind": "SCALAR",
                                ],
                            ],
                        ],
                        [
                            "name": "primaryFunction",
                            "type": [
                                "name": nil,
                                "kind": "NON_NULL",
                                "ofType": [
                                    "name": "String",
                                    "kind": "SCALAR",
                                ],
                            ],
                        ],
                        [
                            "name": "secretBackstory",
                            "type": [
                                "name": "String",
                                "kind": "SCALAR",
                                "ofType": nil,
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
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

        let expected: Map = [
            "data": [
                "__schema": [
                    "queryType": [
                        "fields": [
                            [
                                "name": "droid",
                                "args": [
                                    [
                                        "name": "id",
                                        "description": "id of the droid",
                                        "type": [
                                            "name": nil,
                                            "kind": "NON_NULL",
                                            "ofType": [
                                                "name": "String",
                                                "kind": "SCALAR",
                                            ]
                                        ],
                                        "defaultValue": nil,
                                        ],
                                ],
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
                                    ],
                                ],
                            ],
                            [
                                "name": "human",
                                "args": [
                                    [
                                        "name": "id",
                                        "description": "id of the human",
                                        "type": [
                                            "name": nil,
                                            "kind": "NON_NULL",
                                            "ofType": [
                                                "name": "String",
                                                "kind": "SCALAR",
                                            ]
                                        ],
                                        "defaultValue": nil,
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
        XCTAssertEqual(result, expected)
    }

    func testIntrospectionDroidDescriptionQuery() throws {
        let query = "query IntrospectionDroidDescriptionQuery {" +
                    "    __type(name: \"Droid\") {" +
                    "        name" +
                    "        description" +
                    "    }" +
                    "}"

        let expected: Map = [
            "data": [
                "__type": [
                    "name": "Droid",
                    "description": "A mechanical creature in the Star Wars universe.",
                ],
            ],
        ]

        let result = try starWarsSchema.execute(request: query)
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
