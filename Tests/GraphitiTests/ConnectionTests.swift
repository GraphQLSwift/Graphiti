import Foundation
import Graphiti
import NIO
import XCTest

class ConnectionTests: XCTestCase {
    struct Comment: Codable, Identifiable {
        let id: Int
        let message: String
    }

    struct ConnectionTypeResolver {
        func comments(
            context _: NoContext,
            arguments: PaginationArguments
        ) throws -> Connection<Comment> {
            return try [
                Comment(id: 1, message: "Hello"),
                Comment(id: 2, message: "What's up?"),
                Comment(id: 3, message: "Goodbye"),
            ].connection(from: arguments)
        }
    }

    let schema = {
        try! Schema<ConnectionTypeResolver, NoContext> {
            Type(Comment.self) {
                Field("id", at: \.id)
                Field("message", at: \.message)
            }

            ConnectionType(Comment.self)

            Query {
                Field("comments", at: ConnectionTypeResolver.comments) {
                    Argument("first", at: \.first)
                    Argument("last", at: \.last)
                    Argument("after", at: \.after)
                    Argument("before", at: \.before)
                }
            }
        }
    }()

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    /// Test that connection objects work as expected
    func testConnection() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments {
                        edges {
                            cursor
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "cursor": "MQ==",
                                "node": [
                                    "id": 1,
                                    "message": "Hello",
                                ],
                            ],
                            [
                                "cursor": "Mg==",
                                "node": [
                                    "id": 2,
                                    "message": "What's up?",
                                ],
                            ],
                            [
                                "cursor": "Mw==",
                                "node": [
                                    "id": 3,
                                    "message": "Goodbye",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": false,
                            "hasNextPage": false,
                            "startCursor": "MQ==",
                            "endCursor": "Mw==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that `first` argument works as intended
    func testFirst() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(first: 1) {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 1,
                                    "message": "Hello",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": false,
                            "hasNextPage": true,
                            "startCursor": "MQ==",
                            "endCursor": "MQ==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that `after` argument works as intended
    func testAfter() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(after: "MQ==") {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 2,
                                    "message": "What's up?",
                                ],
                            ],
                            [
                                "node": [
                                    "id": 3,
                                    "message": "Goodbye",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": false,
                            "hasNextPage": false,
                            "startCursor": "Mg==",
                            "endCursor": "Mw==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that mixing `first` and `after` arguments works as intended
    func testFirstAfter() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(first: 1, after: "MQ==") {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 2,
                                    "message": "What's up?",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": false,
                            "hasNextPage": true,
                            "startCursor": "Mg==",
                            "endCursor": "Mg==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that `last` argument works as intended
    func testLast() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(last: 1) {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 3,
                                    "message": "Goodbye",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": true,
                            "hasNextPage": false,
                            "startCursor": "Mw==",
                            "endCursor": "Mw==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that `before` argument works as intended
    func testBefore() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(before: "Mw==") {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 1,
                                    "message": "Hello",
                                ],
                            ],
                            [
                                "node": [
                                    "id": 2,
                                    "message": "What's up?",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": false,
                            "hasNextPage": false,
                            "startCursor": "MQ==",
                            "endCursor": "Mg==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that mixing `last` with `before` argument works as intended
    func testLastBefore() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(last: 1, before: "Mw==") {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 2,
                                    "message": "What's up?",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": true,
                            "hasNextPage": false,
                            "startCursor": "Mg==",
                            "endCursor": "Mg==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that mixing `after` with `before` argument works as intended
    func testAfterBefore() throws {
        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments(after: "MQ==", before: "Mw==") {
                        edges {
                            node {
                                id
                                message
                            }
                        }
                        pageInfo {
                            hasPreviousPage
                            hasNextPage
                            startCursor
                            endCursor
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            [
                                "node": [
                                    "id": 2,
                                    "message": "What's up?",
                                ],
                            ],
                        ],
                        "pageInfo": [
                            "hasPreviousPage": false,
                            "hasNextPage": false,
                            "startCursor": "Mg==",
                            "endCursor": "Mg==",
                        ],
                    ],
                ]
            )
        )
    }

    /// Test that adjusting names using `as` works
    func testNaming() throws {
        struct ChatObject: Codable {
            func messages(
                context _: NoContext,
                arguments: PaginationArguments
            ) throws -> Connection<MessageObject> {
                return try [
                    MessageObject(id: 1, text: "a"),
                    MessageObject(id: 2, text: "b"),
                ].connection(from: arguments)
            }
        }

        struct MessageObject: Codable, Identifiable {
            let id: Int
            let text: String
        }

        struct Resolver {
            func chatObject(context _: NoContext, arguments _: NoArguments) throws -> ChatObject {
                return ChatObject()
            }
        }

        let schema = try Schema<Resolver, NoContext> {
            Type(ChatObject.self, as: "Chat") {
                Field("messages", at: ChatObject.messages, as: Connection<MessageObject>.self) {
                    Argument("first", at: \.first)
                    Argument("after", at: \.after)
                    Argument("last", at: \.last)
                    Argument("before", at: \.before)
                }
            }

            Type(MessageObject.self, as: "Message") {
                Field("id", at: \.id)
                Field("text", at: \.text)
            }

            ConnectionType(MessageObject.self, as: "Message")

            Query {
                Field("chatObject", at: Resolver.chatObject)
            }
        }

        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    chatObject {
                        messages {
                            edges {
                                node {
                                    id
                                    text
                                }
                            }
                        }
                    }
                }
                """,
                resolver: .init(),
                context: NoContext(),
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "chatObject": [
                        "messages": [
                            "edges": [
                                [
                                    "node": [
                                        "id": 1,
                                        "text": "a",
                                    ],
                                ],
                                [
                                    "node": [
                                        "id": 2,
                                        "text": "b",
                                    ],
                                ],
                            ],
                        ],
                    ],
                ]
            )
        )
    }
}
