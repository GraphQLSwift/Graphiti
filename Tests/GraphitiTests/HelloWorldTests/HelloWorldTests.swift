import XCTest
import GraphQL
import NIO
import RxSwift
@testable import Graphiti

let pubsub = PublishSubject<User>()

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
    
    init(id: String, name: String?) {
        self.id = id
        self.name = name
    }
    
    init(_ input: UserInput) {
        self.id = input.id
        self.name = input.name
    }
}

struct UserInput : Codable {
    let id: String
    let name: String?
}

struct UserEvent : Codable {
    let user: User
}

final class HelloContext {
    func hello() -> String {
        "world"
    }
}

extension User {
    func toEvent(context: HelloContext, arguments: NoArguments) throws -> UserEvent {
        return UserEvent(user: self)
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
        User(id: "123", name: "John Doe")
    }
    
    struct AddUserArguments : Codable {
        let user: UserInput
    }
    
    func addUser(context: HelloContext, arguments: AddUserArguments) -> User {
        User(arguments.user)
    }
    
    func subscribeUser(context: HelloContext, arguments: NoArguments) -> Observable<User> {
        pubsub
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
        }

        Input(UserInput.self) {
            InputField("id", at: \.id)
            InputField("name", at: \.name)
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
            SubscriptionField("subscribeUser", at: User.toEvent, atSub: HelloResolver.subscribeUser)
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
    
    // TODO Adjust this to expect an Observable when GraphQL is piped up correctly.
    func testSubscription() throws {
        let subscription = """
        subscription {
            subscribeUser {
                user {
                    id
                    name
                }
            }
        }
        """
        
        let expected = GraphQLResult(data: [
            "subscribeUser": [
                "user": [
                    "name": "John Doe",
                    "id": "123"
                ]
            ]
        ])
        
        let result = try api.subscribe(
            request: subscription,
            context: api.context,
            on: group
        ).wait()
        print(result)
//        let observable = try api.subscribe(
//            request: subscription,
//            context: api.context,
//            on: group
//        ).wait().observable!
        
        let expectation = XCTestExpectation()
        
//        var currentResult = GraphQLResult()
//        let _ = observable.subscribe { event in
//            event.element!.whenSuccess { result in
//                currentResult = result
//                expectation.fulfill()
//            }
//        }
//
//        pubsub.onNext(User(id: "124", name: "Jerry"))
//
//        wait(for: [expectation], timeout: 10)
//
//        XCTAssertEqual(currentResult, expected)
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
