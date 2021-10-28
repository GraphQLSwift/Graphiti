import XCTest
import GraphQL
import NIO
@testable import Graphiti

actor CounterContext {
    var count = 0
    
    func increment() -> Int {
        count += 1
        return count
    }
    
    func decrement() -> Int {
        count -= 1
        return count
    }
}

struct CounterResolver {
    var count: Resolve<CounterContext, Void, Int>
    var increment: Resolve<CounterContext, Void, Int>
    var decrement: Resolve<CounterContext, Void, Int>
}

@available(macOS 12, *)
struct CounterAPI: API {
    let resolver: CounterResolver
    
    let schema = Schema<CounterResolver, CounterContext> {
        Query {
            Field("count", at: \.count)
        }

        Mutation {
            Field("increment", at: \.increment)
            Field("decrement", at: \.decrement)
        }
    }
}

extension CounterResolver {
    static let test = CounterResolver(
        count: { context, _ in
            await context.count
        },
        increment: { context, _ in
            await context.increment()
        },
        decrement: { context, _ in
            await context.decrement()
        }
    )
}

@available(macOS 12, *)
class CounterTests: XCTestCase {
    private let api = CounterAPI(resolver: .test)
    private let context = CounterContext()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    deinit {
        try? self.group.syncShutdownGracefully()
    }
    
    func testCounter() throws {
        var query = "{ count }"
        var expected = GraphQLResult(data: ["count": 0])
        var expectation = XCTestExpectation()
        
        api.execute(
            request: query,
            context: context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
        
        query = """
        mutation {
            increment
        }
        """
        
        expected = GraphQLResult(
            data: ["increment": 1]
        )
        
        expectation = XCTestExpectation()
        
        api.execute(
            request: query,
            context: context,
            on: group
        ).whenSuccess { result in
            XCTAssertEqual(result, expected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
        
        query = """
        mutation {
            decrement
        }
        """
        
        expected = GraphQLResult(
            data: ["decrement": 0]
        )
        
        expectation = XCTestExpectation()
        
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
}

@available(macOS 12, *)
extension CounterTests {
    static var allTests: [(String, (CounterTests) -> () throws -> Void)] {
        return [
            ("testCounter", testCounter),
        ]
    }
}

