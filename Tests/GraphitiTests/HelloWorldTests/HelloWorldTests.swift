import XCTest
import GraphQL
import NIO
@testable import Graphiti

struct ID: Codable {
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

@available(macOS 12, *)
struct User: Codable {
    let id: ID
    let name: String?
    let friends: [User]?
    
    init(id: ID, name: String?, friends: [User]?) {
        self.id = id
        self.name = name
        self.friends = friends
    }
    
    init(_ input: UserInput) {
        self.id = input.id
        self.name = input.name
        
        if let friends = input.friends {
            self.friends = friends.map(User.init)
        } else {
            self.friends = nil
        }
    }
}

struct UserInput: Codable {
    let id: ID
    let name: String?
    let friends: [UserInput]?
}

@available(macOS 12, *)
struct UserEvent: Codable {
    let user: User
}

@available(macOS 12, *)
final class HelloContext {
    func hello() async -> String {
        "world"
    }
}

@available(macOS 12, *)
struct HelloResolver {
    var hello: Resolve<HelloContext, Void, String>
    
    struct FloatArguments: Codable {
        let float: Float
    }
    
    var getFloat: Resolve<HelloContext, FloatArguments, Float>
    
    struct IDArguments: Codable {
        let id: ID
    }
    
    var getId: Resolve<HelloContext, IDArguments, ID>
    var getUser: Resolve<HelloContext, NoArguments, User>
    
    struct AddUserArguments: Codable {
        let user: UserInput
    }
    
    var addUser: Resolve<HelloContext, AddUserArguments, User>
}

@available(macOS 12, *)
struct HelloAPI: API {
    let resolver: HelloResolver
    
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
            Field("hello", at: \.hello)
            
            Field("float", at: \.getFloat) {
                Argument("float", at: \.float)
            }
            
            Field("id", at: \.getId) {
                Argument("id", at: \.id)
            }
            
            Field("user", at: \.getUser)
        }

        Mutation {
            Field("addUser", at: \.addUser) {
                Argument("user", at: \.user)
            }
        }
    }
}

@available(macOS 12, *)
extension HelloResolver {
    static let test = HelloResolver(
        hello: { context, _ in
            await context.hello()
        },
        getFloat: { _, arguments in
            arguments.float
        },
        getId: { _, arguments in
            arguments.id
        },
        getUser: { _, _ in
            User(id: ID("123"), name: "John Doe", friends: nil)
        },
        addUser: { _, arguments in
            User(arguments.user)
        }
    )
}

@available(macOS 12, *)
class HelloWorldTests: XCTestCase {
    private let api = HelloAPI(resolver: .test)
    private let context = HelloContext()
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
            context: context,
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
            context: context,
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
            context: context,
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
            context: context,
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
            context: context,
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
            context: context,
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
        
        let variables: [String: Map] = ["user": ["id": "123", "name": "bob"]]
        
        let expected = GraphQLResult(
            data: ["addUser": ["id": "123", "name": "bob"]]
        )
        
        let expectation = XCTestExpectation()
        
        api.execute(
            request: mutation,
            context: context,
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
        
        let variables: [String: Map] = ["user": ["id": "123", "name": "bob", "friends": [["id": "124", "name": "jeff"]]]]
        
        let expected = GraphQLResult(
            data: ["addUser": ["id": "123", "name": "bob", "friends": [["id": "124", "name": "jeff"]]]]
        )
        
        let expectation = XCTestExpectation()
        
        api.execute(
            request: mutation,
            context: context,
            on: group,
            variables: variables
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}

@available(macOS 12, *)
extension HelloWorldTests {
    static var allTests: [(String, (HelloWorldTests) -> () throws -> Void)] {
        return [
            ("testHello", testHello),
            ("testBoyhowdy", testBoyhowdy),
            ("testScalar", testScalar),
            ("testInput", testInput),
        ]
    }
}
