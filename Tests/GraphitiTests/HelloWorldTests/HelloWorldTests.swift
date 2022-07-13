import XCTest
import GraphQL
import NIO
@testable import Graphiti

struct ID : Codable {
    let id: String
    
    init(_ id: String) {
        self.id = id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.id = try container.decode(String.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
}

struct User : Codable {
    let id: String
    let name: String?
    let friends: [User]?
    
    init(id: String, name: String?, friends: [User]?) {
        self.id = id
        self.name = name
        self.friends = friends
    }
    
    init(_ input: UserInput) {
        self.id = input.id
        self.name = input.name
        if let friends = input.friends {
            self.friends = friends.map{ User($0) }
        } else {
            self.friends = nil
        }
    }
    
    func toEvent(context: HelloContext, arguments: NoArguments) throws -> UserEvent {
        return UserEvent(user: self)
    }
}

struct UserInput : Codable {
    let id: String
    let name: String?
    let friends: [UserInput]?
}

struct UserEvent : Codable {
    let user: User
}

final class HelloContext {
    func hello() -> String {
        "world"
    }
}

struct HelloResolver {
    func hello(context: HelloContext, arguments: NoArguments) -> String {
        context.hello()
    }
    
    func asyncHello(
        context: HelloContext,
        arguments: NoArguments,
        group: EventLoopGroup
    ) -> EventLoopFuture<String> {
        group.next().makeSucceededFuture(context.hello())
    }
    
    struct FloatArguments : Codable {
        let float: Float
    }
    
    func getFloat(context: HelloContext, arguments: FloatArguments) -> Float {
        arguments.float
    }
    
    struct IDArguments : Codable {
        let id: ID
    }
    
    func getId(context: HelloContext, arguments: IDArguments) -> ID {
        arguments.id
    }
    
    func getUser(context: HelloContext, arguments: NoArguments) -> User {
        User(id: "123", name: "John Doe", friends: nil)
    }
    
    struct AddUserArguments : Codable {
        let user: UserInput
    }
    
    func addUser(context: HelloContext, arguments: AddUserArguments) -> User {
        User(arguments.user)
    }
}

struct HelloAPI : API {
    let resolver = HelloResolver()
    let context = HelloContext()
    
    let schema = try! Schema<HelloResolver, HelloContext> {
        Scalar(Float.self)
            .description("The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).")

        Scalar(ID.self)
            .description("The `ID` scalar type represents a unique identifier.")
        
        Type(User.self) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("friends", at: \.friends, as: [TypeReference<User>]?.self)
        }

        Input(UserInput.self) {
            InputField("id", at: \.id)
            InputField("name", at: \.name)
            InputField("friends", at: \.friends, as: [TypeReference<UserInput>]?.self)
        }
        
        Type(UserEvent.self) {
            Field("user", at: \.user)
        }
        
        Query {
            Field("hello", at: HelloResolver.hello)
            Field("asyncHello", at: HelloResolver.asyncHello)
            
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

class HelloWorldTests : XCTestCase {
    private let api = HelloAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    deinit {
        try? self.group.syncShutdownGracefully()
    }
    
    func testHello() throws {
        let query = "{ hello }"
        let expected = GraphQLResult(data: ["hello": "world"])
        
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
    
    func testHelloAsync() throws {
        let query = "{ asyncHello }"
        let expected = GraphQLResult(data: ["asyncHello": "world"])
        
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

    func testBoyhowdy() throws {
        let query = "{ boyhowdy }"

        let expected = GraphQLResult(
            errors: [
                GraphQLError(
                    message: "Cannot query field \"boyhowdy\" on type \"Query\".",
                    locations: [SourceLocation(line: 1, column: 3)]
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
    
    func testScalar() throws {
        var query: String
        var expected = GraphQLResult(data: ["float": 4.0])

        query = """
        query Query($float: Float!) {
            float(float: $float)
        }
        """

        let expectationA = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group,
            variables: ["float": 4]
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectationA.fulfill()
        }
        
        wait(for: [expectationA], timeout: 10)

        query = """
        query Query {
            float(float: 4)
        }
        """
        
        let expectationB = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectationB.fulfill()
        }
        
        wait(for: [expectationB], timeout: 10)
        
        query = """
        query Query($id: String!) {
            id(id: $id)
        }
        """
        
        expected = GraphQLResult(data: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"])
        
        let expectationC = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group,
            variables: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"]
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectationC.fulfill()
        }
        
        wait(for: [expectationC], timeout: 10)
        
        query = """
        query Query {
            id(id: "85b8d502-8190-40ab-b18f-88edd297d8b6")
        }
        """
        
        let expectationD = XCTestExpectation()
        
        api.execute(
            request: query,
            context: api.context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectationD.fulfill()
        }
        
        wait(for: [expectationD], timeout: 10)
    }

    func testInput() throws {
        let mutation = """
        mutation addUser($user: UserInput!) {
            addUser(user: $user) {
                id,
                name
            }
        }
        """
        
        let variables: [String: Map] = ["user" : [ "id" : "123", "name" : "bob" ]]
        
        let expected = GraphQLResult(
            data: ["addUser" : [ "id" : "123", "name" : "bob" ]]
        )
        
        let expectation = XCTestExpectation()
        
        api.execute(
            request: mutation,
            context: api.context,
            on: group,
            variables: variables
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testInputRecursive() throws {
        let mutation = """
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
        """
        
        let variables: [String: Map] = ["user" : [ "id" : "123", "name" : "bob", "friends": [["id": "124", "name": "jeff"]]]]
        
        let expected = GraphQLResult(
            data: ["addUser" : [ "id" : "123", "name" : "bob", "friends": [["id": "124", "name": "jeff"]]]]
        )
        
        let expectation = XCTestExpectation()
        
        api.execute(
            request: mutation,
            context: api.context,
            on: group,
            variables: variables
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}

extension HelloWorldTests {
    static var allTests: [(String, (HelloWorldTests) -> () throws -> Void)] {
        return [
            ("testHello", testHello),
            ("testHelloAsync", testHelloAsync),
            ("testBoyhowdy", testBoyhowdy),
            ("testScalar", testScalar),
            ("testInput", testInput),
        ]
    }
}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
let pubsub = SimplePubSub<User>()

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension HelloResolver {
    func subscribeUser(context: HelloContext, arguments: NoArguments) -> EventStream<User> {
        pubsub.subscribe()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
// Same as the one above, except with a few subscription fields
struct HelloSubscribeAPI : API {
    let resolver = HelloResolver()
    let context = HelloContext()
    
    let schema = try! Schema<HelloResolver, HelloContext> {
        Scalar(Float.self)
            .description("The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).")

        Scalar(ID.self)
            .description("The `ID` scalar type represents a unique identifier.")
        
        Type(User.self) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("friends", at: \.friends, as: [TypeReference<User>]?.self)
        }

        Input(UserInput.self) {
            InputField("id", at: \.id)
            InputField("name", at: \.name)
            InputField("friends", at: \.friends, as: [TypeReference<UserInput>]?.self)
        }
        
        Type(UserEvent.self) {
            Field("user", at: \.user)
        }
        
        Query {
            Field("hello", at: HelloResolver.hello)
            Field("asyncHello", at: HelloResolver.asyncHello)
            
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
        
        Subscription {
            SubscriptionField("subscribeUser", as: User.self, atSub: HelloResolver.subscribeUser)
            SubscriptionField("subscribeUserEvent", at: User.toEvent, atSub: HelloResolver.subscribeUser)
        }
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
class HelloWorldSubscribeTests : XCTestCase {
    private let api = HelloSubscribeAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    /// Tests subscription when the sourceEventStream type matches the resolved type (i.e. the normal resolution function should just short-circuit to the sourceEventStream object)
    func testSubscriptionSelf() async throws {
        let request = """
        subscription {
            subscribeUser {
                id
                name
            }
        }
        """
        
        let subscriptionResult = try api.subscribe(
            request: request,
            context: api.context,
            on: group
        ).wait()
        guard let subscription = subscriptionResult.stream else {
            XCTFail(subscriptionResult.errors.description)
            return
        }
        guard let stream = subscription as? ConcurrentEventStream else {
            XCTFail("stream isn't ConcurrentEventStream")
            return
        }
        var iterator = stream.stream.makeAsyncIterator()
        
        pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))
        
        let result = try await iterator.next()?.get()
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "subscribeUser": [
                    "id": "124",
                    "name": "Jerry"
                ]
            ])
        )
    }
    
    /// Tests subscription when the sourceEventStream type does not match the resolved type (i.e. there is a non-trivial resolution function that transforms the sourceEventStream object)
    func testSubscriptionEvent() async throws {
        let request = """
        subscription {
            subscribeUserEvent {
                user {
                    id
                    name
                }
            }
        }
        """
        
        let subscriptionResult = try api.subscribe(
            request: request,
            context: api.context,
            on: group
        ).wait()
        guard let subscription = subscriptionResult.stream else {
            XCTFail(subscriptionResult.errors.description)
            return
        }
        guard let stream = subscription as? ConcurrentEventStream else {
            XCTFail("stream isn't ConcurrentEventStream")
            return
        }
        var iterator = stream.stream.makeAsyncIterator()
        
        pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))
        
        let result = try await iterator.next()?.get()
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "subscribeUserEvent": [
                    "user": [
                        "id": "124",
                        "name": "Jerry"
                    ]
                ]
            ])
        )
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
/// A very simple publish/subscriber used for testing
class SimplePubSub<T> {
    private var subscribers: [Subscriber<T>]
    
    init() {
        subscribers = []
    }
    
    func publish(event: T) {
        for subscriber in subscribers {
            subscriber.callback(event)
        }
    }
    
    func cancel() {
        for subscriber in subscribers {
            subscriber.cancel()
        }
    }
    
    func subscribe() -> ConcurrentEventStream<T> {
        let asyncStream = AsyncThrowingStream<T, Error> { continuation in
            let subscriber = Subscriber<T>(
                callback: { newValue in
                    continuation.yield(newValue)
                },
                cancel: {
                    continuation.finish()
                }
            )
            subscribers.append(subscriber)
            return
        }
        return ConcurrentEventStream<T>.init(asyncStream)
    }
}

struct Subscriber<T> {
    let callback: (T) -> Void
    let cancel: () -> Void
}

#endif
