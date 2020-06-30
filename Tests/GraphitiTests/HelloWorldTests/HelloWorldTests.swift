import XCTest
@testable import Graphiti
import GraphQL
import NIO

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

struct User : Codable, Keyable {
    enum Keys : String {
        case id
        case name
    }
    
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

struct UserInput : Codable, Keyable {
    enum Keys : String {
        case id
        case name
    }
    
    let id: String
    let name: String?
}

final class Context {
    func hello() -> String {
        "world"
    }
}

struct HelloRoot : Keyable {
    enum Keys : String {
        case hello
        case asyncHello
        case float
        case id
        case user
        case addUser
    }
    
    func hello(context: Context, arguments: NoArguments) -> String {
        context.hello()
    }
    
    func asyncHello(
        context: Context,
        arguments: NoArguments,
        group: EventLoopGroup
    ) -> EventLoopFuture<String> {
        group.next().makeSucceededFuture(context.hello())
    }
    
    struct FloatArguments : Codable {
        let float: Float
    }
    
    func getFloat(context: Context, arguments: FloatArguments) -> Float {
        arguments.float
    }
    
    struct IDArguments : Codable {
        let id: ID
    }
    
    func getId(context: Context, arguments: IDArguments) -> ID {
        arguments.id
    }
    
    func getUser(context: Context, arguments: NoArguments) -> User {
        User(id: "123", name: "John Doe")
    }
    
    struct AddUserArguments : Codable {
        let user: UserInput
    }
    
    func addUser(context: Context, arguments: AddUserArguments) -> User {
        User(arguments.user)
    }
}

struct HelloAPI : API {
    let root = HelloRoot()
    let context = Context()
    
    let schema = try! Schema<HelloRoot, Context> { schema in
        schema.scalar(Float.self)
            .description("The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).")

        schema.scalar(ID.self)
            .description("The `ID` scalar type represents a unique identifier.")
        
        schema.type(User.self) { type in
            type.field(.id, at: \.id)
            type.field(.name, at: \.name)
        }
        
        schema.input(UserInput.self) { input in
            input.field(.id, at: \.id)
            input.field(.name, at: \.name)
        }
        
        schema.query { query in
            query.field(.hello, at: HelloRoot.hello)
            query.field(.asyncHello, at: HelloRoot.asyncHello)
            query.field(.float, at: HelloRoot.getFloat)
            query.field(.id, at: HelloRoot.getId)
            query.field(.user, at: HelloRoot.getUser)
        }
        
        schema.mutation { mutation in
            mutation.field(.addUser, at: HelloRoot.addUser)
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
