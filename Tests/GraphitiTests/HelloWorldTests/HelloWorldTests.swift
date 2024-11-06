@testable import Graphiti
import GraphQL
import NIO
import XCTest

struct ID: Codable {
    let id: String

    init(_ id: String) {
        self.id = id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        id = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

struct User {
    let id: String
    let name: String?
    let friends: [User]?

    init(id: String, name: String?, friends: [User]?) {
        self.id = id
        self.name = name
        self.friends = friends
    }

    init(_ input: UserInput) {
        id = input.id
        name = input.name
        if let friends = input.friends {
            self.friends = friends.map { User($0) }
        } else {
            friends = nil
        }
    }

    func toEvent(context _: HelloContext, arguments _: NoArguments) throws -> UserEvent {
        return UserEvent(user: self)
    }
}

struct UserInput: Codable {
    let id: String
    let name: String?
    let friends: [UserInput]?
}

struct UserEvent {
    let user: User
}

final class HelloContext {
    func hello() -> String {
        "world"
    }
}

struct HelloResolver {
    func hello(context: HelloContext, arguments _: NoArguments) -> String {
        context.hello()
    }

    func futureHello(
        context: HelloContext,
        arguments _: NoArguments,
        group: EventLoopGroup
    ) -> EventLoopFuture<String> {
        group.next().makeSucceededFuture(context.hello())
    }

    struct FloatArguments: Codable {
        let float: Float
    }

    func getFloat(context _: HelloContext, arguments: FloatArguments) -> Float {
        arguments.float
    }

    struct IDArguments: Codable {
        let id: ID
    }

    func getId(context _: HelloContext, arguments: IDArguments) -> ID {
        arguments.id
    }

    func getUser(context _: HelloContext, arguments _: NoArguments) -> User {
        User(id: "123", name: "John Doe", friends: nil)
    }

    struct AddUserArguments: Codable {
        let user: UserInput
    }

    func addUser(context _: HelloContext, arguments: AddUserArguments) -> User {
        User(arguments.user)
    }
}

struct HelloAPI: API {
    let resolver = HelloResolver()
    let context = HelloContext()

    let schema = try! Schema<HelloResolver, HelloContext> {
        Scalar(Float.self)
            .description(
                "The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)."
            )

        Scalar(ID.self)
            .description("The `ID` scalar type represents a unique identifier.")

        Type(User.self) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("friends", at: \.friends)
        }

        Input(UserInput.self) {
            InputField("id", at: \.id)
            InputField("name", at: \.name)
            InputField("friends", at: \.friends)
        }

        Type(UserEvent.self) {
            Field("user", at: \.user)
        }

        Query {
            Field("hello", at: HelloResolver.hello)
            Field("futureHello", at: HelloResolver.futureHello)

            Field("float", at: HelloResolver.getFloat) {
                Argument("float", at: \.float)
            }

            Field("id", at: HelloResolver.getId) {
                Argument("id", at: \.id)
            }

            Field("user", at: HelloResolver.getUser)
        }

        Mutation {
            Field("addUser", at: HelloResolver.addUser) {
                Argument("user", at: \.user)
            }
        }
    }
}

class HelloWorldTests: XCTestCase {
    private let api = HelloAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? self.group.syncShutdownGracefully()
    }

    func testHello() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ hello }",
                context: api.context,
                on: group
            ).wait(),
            GraphQLResult(data: ["hello": "world"])
        )
    }

    func testFutureHello() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ futureHello }",
                context: api.context,
                on: group
            ).wait(),
            GraphQLResult(data: ["futureHello": "world"])
        )
    }

    func testBoyhowdy() throws {
        XCTAssertEqual(
            try api.execute(
                request: "{ boyhowdy }",
                context: api.context,
                on: group
            ).wait(),
            GraphQLResult(
                errors: [
                    GraphQLError(
                        message: "Cannot query field \"boyhowdy\" on type \"Query\".",
                        locations: [SourceLocation(line: 1, column: 3)]
                    ),
                ]
            )
        )
    }

    func testScalar() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                query Query($float: Float!) {
                    float(float: $float)
                }
                """,
                context: api.context,
                on: group,
                variables: ["float": 4]
            ).wait(),
            GraphQLResult(data: ["float": 4.0])
        )

        XCTAssertEqual(
            try api.execute(
                request: """
                query Query {
                    float(float: 4)
                }
                """,
                context: api.context,
                on: group
            ).wait(),
            GraphQLResult(data: ["float": 4.0])
        )

        XCTAssertEqual(
            try api.execute(
                request: """
                query Query($id: ID!) {
                    id(id: $id)
                }
                """,
                context: api.context,
                on: group,
                variables: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"]
            ).wait(),
            GraphQLResult(data: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"])
        )

        XCTAssertEqual(
            try api.execute(
                request: """
                query Query {
                    id(id: "85b8d502-8190-40ab-b18f-88edd297d8b6")
                }
                """,
                context: api.context,
                on: group
            ).wait(),
            GraphQLResult(data: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"])
        )
    }

    func testInput() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                mutation addUser($user: UserInput!) {
                    addUser(user: $user) {
                        id,
                        name
                    }
                }
                """,
                context: api.context,
                on: group,
                variables: ["user": ["id": "123", "name": "bob"]]
            ).wait(),
            GraphQLResult(
                data: ["addUser": ["id": "123", "name": "bob"]]
            )
        )
    }

    func testInputRequest() throws {
        XCTAssertEqual(
            try api.execute(
                request: GraphQLRequest(
                    query: """
                    mutation addUser($user: UserInput!) {
                        addUser(user: $user) {
                            id,
                            name
                        }
                    }
                    """,
                    variables: ["user": ["id": "123", "name": "bob"]]
                ),
                context: api.context,
                on: group
            ).wait(),
            GraphQLResult(
                data: ["addUser": ["id": "123", "name": "bob"]]
            )
        )
    }

    func testInputRecursive() throws {
        XCTAssertEqual(
            try api.execute(
                request: """
                mutation addUser($user: UserInput!) {
                    addUser(user: $user) {
                        id,
                        name,
                        friends {
                            id,
                            name
                        }
                    }
                }
                """,
                context: api.context,
                on: group,
                variables: [
                    "user": [
                        "id": "123",
                        "name": "bob",
                        "friends": [["id": "124", "name": "jeff"]],
                    ],
                ]
            ).wait(),
            GraphQLResult(
                data: [
                    "addUser": [
                        "id": "123",
                        "name": "bob",
                        "friends": [["id": "124", "name": "jeff"]],
                    ],
                ]
            )
        )
    }
}
