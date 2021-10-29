import XCTest
import GraphQL
import NIO
@testable import Graphiti

@available(macOS 12, *)
struct Counter: Encodable {
    var count: Int
}

@available(macOS 12, *)
actor CounterContext {
    var counter: Counter
    
    init(counter: Counter) {
        self.counter = counter
    }
    
    func increment() -> Counter {
        counter.count += 1
        return counter
    }
    
    func decrement() -> Counter {
        counter.count -= 1
        return counter
    }
    
    func increment(by count: Int) -> Counter {
        counter.count += count
        return counter
    }
    
    func decrement(by count: Int) -> Counter {
        counter.count -= count
        return counter
    }
}

@available(macOS 12, *)
struct CounterResolver {
    var counter: (CounterContext, Void) async throws -> Counter
    var increment: (CounterContext, Void) async throws -> Counter
    var decrement: (CounterContext, Void) async throws -> Counter
   
    struct IncrementByArguments: Decodable {
        let count: Int
    }
    
    var incrementBy: (CounterContext, IncrementByArguments) async throws -> Counter
    
    struct DecrementByArguments: Decodable {
        let count: Int
    }
    
    var decrementBy: (CounterContext, DecrementByArguments) async throws -> Counter
}

@available(macOS 12, *)
struct CounterAPI {
    let schema = Schema<CounterResolver, CounterContext> {
        Type(Counter.self) {
            Field("count", at: \.count)
        }
        
        Query {
            Field("counter", at: \.counter)
        }

        Mutation {
            Field("increment", at: \.increment)
            Field("decrement", at: \.decrement)
            
            Field("incrementBy", at: \.incrementBy) {
                Argument("count", at: \.count)
            }
            
            Field("decrementBy", at: \.decrementBy) {
                Argument("count", at: \.count)
            }
        }
    }
}

@available(macOS 12, *)
extension CounterContext {
    static let live = CounterContext(counter: Counter(count: 0))
}

@available(macOS 12, *)
extension CounterResolver {
    static let live = CounterResolver(
        counter: { context, _ in
            await context.counter
        },
        increment: { context, _ in
            await context.increment()
        },
        decrement: { context, _ in
            await context.decrement()
        },
        incrementBy: { context, arguments in
            await context.increment(by: arguments.count)
        },
        decrementBy: { context, arguments in
            await context.decrement(by: arguments.count)
        }
    )
}

@available(macOS 12, *)
class CounterTests: XCTestCase {
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    deinit {
        try? self.group.syncShutdownGracefully()
    }
    
    func testCounter() throws {
        let api = CounterAPI()
        var query = "query { counter { count } }"
        var expected = GraphQLResult(data: ["counter": ["count": 0]])
        
        var result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
        
        query = "mutation { increment { count } }"
        expected = GraphQLResult(data: ["increment": ["count": 1]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
        
        XCTAssertEqual(result, expected)
        
        query = "mutation { decrement { count } }"
        expected = GraphQLResult(data: ["decrement": ["count": 0]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
            
        XCTAssertEqual(result, expected)
    
        query = "mutation { incrementBy(count: 5) { count } }"
        expected = GraphQLResult(data: ["incrementBy": ["count": 5]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
         
        XCTAssertEqual(result, expected)
        
        query = "mutation { decrementBy(count: 5) { count } }"
        expected = GraphQLResult(data: ["decrementBy": ["count": 0]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
         
        XCTAssertEqual(result, expected)
    }
}

@available(macOS 12, *)
extension CounterTests {
    static var allTests: [(String, (CounterTests) -> () throws -> Void)] {
        return [
            ("testCounter", testCounter),
        ]
    }
}

