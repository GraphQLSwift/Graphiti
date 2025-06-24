import GraphQL
import XCTest

@testable import Graphiti

class StarWarsIntrospectionTests: XCTestCase {
    private let api = StarWarsAPI()

    func testIntrospectionTypeQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionTypeQuery {
                __schema {
                    types {
                        name
                    }
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
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
                            ],
                        ],
                    ],
                ]
            )
        )
    }

    func testIntrospectionQueryTypeQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionQueryTypeQuery {
                __schema {
                    queryType {
                        name
                    }
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "__schema": [
                        "queryType": [
                            "name": "Query",
                        ],
                    ],
                ]
            )
        )
    }

    func testIntrospectionDroidTypeQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionDroidTypeQuery {
                __type(name: \"Droid\") {
                    name
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "__type": [
                        "name": "Droid",
                    ],
                ]
            )
        )
    }

    func testIntrospectionDroidKindQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionDroidKindQuery {
                __type(name: \"Droid\") {
                    name
                    kind
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "__type": [
                        "name": "Droid",
                        "kind": "OBJECT",
                    ],
                ]
            )
        )
    }

    func testIntrospectionCharacterKindQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionCharacterKindQuery {
                __type(name: \"Character\") {
                    name
                    kind
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "__type": [
                        "name": "Character",
                        "kind": "INTERFACE",
                    ],
                ]
            )
        )
    }

    func testIntrospectionDroidFieldsQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionDroidFieldsQuery {
                __type(name: \"Droid\") {
                    name
                    fields {
                        name
                        type {
                            name
                            kind
                        }
                    }
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "__type": [
                        "name": "Droid",
                        "fields": [
                            [
                                "name": "appearsIn",
                                "type": [
                                    "name": nil,
                                    "kind": "NON_NULL",
                                ],
                            ],
                            [
                                "name": "friends",
                                "type": [
                                    "name": nil,
                                    "kind": "NON_NULL",
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
                ]
            )
        )
    }

    func testIntrospectionDroidNestedFieldsQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionDroidNestedFieldsQuery {
                __type(name: \"Droid\") {
                    name
                    fields {
                        name
                        type {
                            name
                            kind
                            ofType {
                                name
                                kind
                            }
                        }
                    }
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
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
                                        "kind": "LIST",
                                    ],
                                ],
                            ],
                            [
                                "name": "friends",
                                "type": [
                                    "name": nil,
                                    "kind": "NON_NULL",
                                    "ofType": [
                                        "name": nil,
                                        "kind": "LIST",
                                    ],
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
                ]
            )
        )
    }

    func testIntrospectionFieldArgsQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionFieldArgsQuery {
                __schema {
                    queryType {
                        fields {
                            name
                            args {
                                name
                                description
                                type {
                                    name
                                    kind
                                    ofType {
                                        name
                                        kind
                                    }
                                }
                                defaultValue
                                }
                        }
                    }
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
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
                                                ],
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
                                                "ofType": nil,
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
                                            "description": "Id of the human.",
                                            "type": [
                                                "name": nil,
                                                "kind": "NON_NULL",
                                                "ofType": [
                                                    "name": "String",
                                                    "kind": "SCALAR",
                                                ],
                                            ],
                                            "defaultValue": nil,
                                        ],
                                    ],
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
                                                ],
                                            ],
                                            "defaultValue": "\"R2-D2\"",
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ]
            )
        )
    }

    func testIntrospectionDroidDescriptionQuery() async throws {
        let result = try await api.execute(
            request: """
            query IntrospectionDroidDescriptionQuery {
                __type(name: \"Droid\") {
                    name
                    description
                }
            }
            """,
            context: StarWarsContext()
        )
        XCTAssertEqual(
            result,
            GraphQLResult(
                data: [
                    "__type": [
                        "name": "Droid",
                        "description": "A mechanical creature in the Star Wars universe.",
                    ],
                ]
            )
        )
    }
}
