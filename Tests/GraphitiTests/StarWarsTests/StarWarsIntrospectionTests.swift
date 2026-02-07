@testable import Graphiti
import GraphQL
import Testing

struct StarWarsIntrospectionTests {
    private let api = StarWarsAPI()

    @Test func introspectionTypeQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionQueryTypeQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionDroidTypeQuery() async throws {
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
        #expect(
            result ==
                GraphQLResult(
                    data: [
                        "__type": [
                            "name": "Droid",
                        ],
                    ]
                )
        )
    }

    @Test func introspectionDroidKindQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionCharacterKindQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionDroidFieldsQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionDroidNestedFieldsQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionFieldArgsQuery() async throws {
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
        #expect(
            result ==
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

    @Test func introspectionDroidDescriptionQuery() async throws {
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
        #expect(
            result ==
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
