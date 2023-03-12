import Foundation
import Graphiti
import NIO
import XCTest

class ConnectionSchemaTests: XCTestCase {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    func testConnectionAddFields() throws {
        let schema = try Schema<ConnectionTypeResolver, NoContext> {
            Type(Comment.self) {
                Field("id", at: \.id)
                Field("message", at: \.message)
            }

            ConnectionType(
                Comment.self,
                connectionFields: {
                    Field("total", at: Connection.total)
                }
            )

            Query {
                Field("comments", at: ConnectionTypeResolver.comments)
            }
        }

        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments {
                        total
                    }
                }
                """,
                resolver: resolver,
                context: context,
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "total": 3,
                    ],
                ]
            )
        )
    }

    func testEdgeAddFields() throws {
        let schema = try Schema<ConnectionTypeResolver, NoContext> {
            Type(Comment.self) {
                Field("id", at: \.id)
                Field("message", at: \.message)
            }

            ConnectionType(
                Comment.self,
                edgeFields: {
                    Field("messageLength", at: Edge.messageLength)
                }
            )

            Query {
                Field("comments", at: ConnectionTypeResolver.comments)
            }
        }

        XCTAssertEqual(
            try schema.execute(
                request: """
                {
                    comments {
                        edges {
                            messageLength
                        }
                    }
                }
                """,
                resolver: resolver,
                context: context,
                eventLoopGroup: eventLoopGroup
            ).wait(),
            .init(
                data: [
                    "comments": [
                        "edges": [
                            ["messageLength": 5],
                            ["messageLength": 10],
                            ["messageLength": 7],
                        ],
                    ],
                ]
            )
        )
    }
}

// MARK: Connection Extensions

private extension Connection {
    func total(context _: NoContext, arguments _: NoArguments) throws -> Int {
        return edges.count
    }
}

private extension Edge where Node == Comment {
    func messageLength(context _: NoContext, arguments _: NoArguments) throws -> Int {
        return node.message.count
    }
}

// MARK: Schema

private struct Comment: Codable, Identifiable {
    let id: Int
    let message: String
}

private struct ConnectionTypeResolver {
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

private let resolver = ConnectionTypeResolver()
private let context = NoContext()
