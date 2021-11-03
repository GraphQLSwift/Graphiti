import XCTest
import GraphQL
import NIO
@testable import Graphiti

@available(macOS 12, *)
struct Count: Encodable {
    var value: Int
}

@available(macOS 12, *)
actor CounterState {
    var count: Count
    
    init(count: Count) {
        self.count = count
    }
    
    func increment() -> Count {
        count.value += 1
        return count
    }
    
    func decrement() -> Count {
        count.value -= 1
        return count
    }
    
    func increment(by amount: Int) -> Count {
        count.value += amount
        return count
    }
    
    func decrement(by amount: Int) -> Count {
        count.value -= amount
        return count
    }
}

@available(macOS 12, *)
struct CounterContext {
    var count: () async -> Count
    var increment: () async -> Count
    var decrement: () async -> Count
    var incrementBy: (_ amount: Int) async -> Count
    var decrementBy: (_ amount: Int) async -> Count
}

@available(macOS 12, *)
struct CounterResolver {
    var count: (CounterContext, Void) async throws -> Count
    var increment: (CounterContext, Void) async throws -> Count
    var decrement: (CounterContext, Void) async throws -> Count
   
    struct IncrementByArguments: Decodable {
        let amount: Int
    }
    
    var incrementBy: (CounterContext, IncrementByArguments) async throws -> Count
    
    struct DecrementByArguments: Decodable {
        let amount: Int
    }
    
    var decrementBy: (CounterContext, DecrementByArguments) async throws -> Count
}

@available(macOS 12, *)
struct CounterAPI {
    let schema = Schema<CounterResolver, CounterContext> {
        "Description"
        Type(Count.self) {
            Field("value", at: \.value)
        }
        
        Query {
            Field("count", at: \.count)
        }

        Mutation {
            Field("increment", at: \.increment)
            Field("decrement", at: \.decrement)
            
            Field("incrementBy", at: \.incrementBy) {
                Argument("amount", at: \.amount)
            }
            
            Field("decrementBy", at: \.decrementBy) {
                Argument("amount", at: \.amount)
            }
        }
    }
}

@available(macOS 12, *)
extension CounterContext {
    static let live: CounterContext = {
        let count = Count(value: 0)
        let state = CounterState(count: count)
        
        return CounterContext(
            count: {
                await state.count
            },
            increment: {
                await state.increment()
            },
            decrement: {
                await state.decrement()
            },
            incrementBy: { count in
                await state.increment(by: count)
            },
            decrementBy: { count in
                await state.decrement(by: count)
            }
        )
    }()
}

@available(macOS 12, *)
extension CounterResolver {
    static let live = CounterResolver(
        count: { context, _ in
            await context.count()
        },
        increment: { context, _ in
            await context.increment()
        },
        decrement: { context, _ in
            await context.decrement()
        },
        incrementBy: { context, arguments in
            await context.incrementBy(arguments.amount)
        },
        decrementBy: { context, arguments in
            await context.decrementBy(arguments.amount)
        }
    )
}

#warning("TODO: Move this to GraphQL")
extension GraphQLResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}



@available(macOS 12, *)
class CounterTests: XCTestCase {
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    deinit {
        try? self.group.syncShutdownGracefully()
    }
    
    func testDirective() throws {
        struct User: Encodable {
            let name: String
        }
        
        struct Context {
            
        }
        
        struct Resolver {
            let user: User
        }
        
        struct DelegateField: Decodable, ObjectDirective, InterfaceDirective {
            let name: String
            
            func object<Resolver, Context, ObjectType>(object: Object<Resolver, Context, ObjectType>) where ObjectType: Encodable {
//                object.fields.append(Graphiti.Field<ObjectType, Context, String, NoArguments>.init(
//                    name: name,
//                    arguments: [],
//                    resolve: { object in
//                        { _, _, group in
//                            group.next().makeCompletedFuture(.success("Yo"))
//                        }
//                    }
//                ))
            }
            
            func interface<Resolver, Context, InterfaceType>(interface: Interface<Resolver, Context, InterfaceType>) {
                
            }
        }
        
        #warning("TODO: Move Decodable requirement from ArgumentComponent to Argument")
        struct Lowercased: Decodable, FieldDefinitionDirective, FieldDirective {
            func fieldDefinition<ObjectType, Context, FieldType, Arguments>(field: Graphiti.Field<ObjectType, Context, FieldType, Arguments>) where Arguments: Decodable {
                let resolve = field.resolve

                field.resolve = { object in
                    { context, arguments, group in
                        try resolve(object)(context, arguments, group).map { value in
                            guard let string = value as? String else {
                                return value
                            }

                            return string.lowercased()
                        }
                    }
                }
            }
            
            func field<ObjectType, Context, Arguments>(resolve: @escaping AsyncResolve<ObjectType, Context, Arguments, Any?>) -> AsyncResolve<ObjectType, Context, Arguments, Any?> {
                { object in
                    { context, arguments, group in
                        try resolve(object)(context, arguments, group).map { value in
                            guard let string = value as? String else {
                                return value
                            }

                            return string.lowercased()
                        }
                    }
                }
            }
        }
        
        struct Uppercased: Decodable, FieldDefinitionDirective, FieldDirective {
            func fieldDefinition<ObjectType, Context, FieldType, Arguments>(field: Graphiti.Field<ObjectType, Context, FieldType, Arguments>) where Arguments: Decodable {
                let resolve = field.resolve

                field.resolve = { object in
                    { context, arguments, group in
                        try resolve(object)(context, arguments, group).map { value in
                            guard let string = value as? String else {
                                return value
                            }

                            return string.uppercased()
                        }
                    }
                }
            }
            
            func field<ObjectType, Context, Arguments>(resolve: @escaping AsyncResolve<ObjectType, Context, Arguments, Any?>) -> AsyncResolve<ObjectType, Context, Arguments, Any?> {
                { object in
                    { context, arguments, group in
                        try resolve(object)(context, arguments, group).map { value in
                            guard let string = value as? String else {
                                return value
                            }

                            return string.uppercased()
                        }
                    }
                }
            }
        }
     
        let schema = Schema<Resolver, Context> {
            Directive(DelegateField.self) {
                Argument("name", of: String.self, at: \.name)
            } on: {
                DirectiveLocation(.object)
                DirectiveLocation(.interface)
            }
            #warning("TODO: Implement repeatable directives")
//            .repeatable()
            
            Directive(Lowercased.self) {
                DirectiveLocation(.fieldDefinition)
                DirectiveLocation(.field)
            }
            
            Directive(Uppercased.self) {
                DirectiveLocation(.fieldDefinition)
                DirectiveLocation(.field)
            }
            
            Type(User.self) {
                Field("name", of: String.self, at: \.name)
//                    .directive(Lowercased())
//                    .directive(Uppercased())
            }
            .directive(DelegateField(name: "salute"))
            
            Query {
                Field.init("user", of: User.self, at: \.user)
            }
        }
        
        #warning("TODO: Add directives property to all types and print them in printSchema")
        debugPrint(schema)
        
        let result = try schema.execute(
            request: "query { user { name @lowercased @uppercased } }",
            resolver: Resolver(user: User(name: "Paulo")),
            context: Context(),
            on: group
        ).wait()
        
        
        debugPrint(result)
    }
    
    func testCounter() throws {
        let api = CounterAPI()
        
        var query = """
        query {
          count {
            value
          }
        }
        """
        
        var expected = GraphQLResult(data: ["count": ["value": 0]])
        
        var result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
       
        debugPrint(result)
        XCTAssertEqual(result, expected)
        
        query = """
        mutation {
          increment {
            value
          }
        }
        """
        expected = GraphQLResult(data: ["increment": ["value": 1]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
       
        debugPrint(result)
        XCTAssertEqual(result, expected)
        
        query = """
        mutation {
          decrement {
            value
          }
        }
        """
        expected = GraphQLResult(data: ["decrement": ["value": 0]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
            
        debugPrint(result)
        XCTAssertEqual(result, expected)
    
        query = """
        mutation {
          incrementBy(amount: 5) {
              value
          }
        }
        """
        expected = GraphQLResult(data: ["incrementBy": ["value": 5]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
         
        debugPrint(result)
        XCTAssertEqual(result, expected)
        
        query = """
        mutation {
          decrementBy(amount: 5) {
            value
          }
        }
        """
        expected = GraphQLResult(data: ["decrementBy": ["value": 0]])
        
        result = try api.schema.execute(
            request: query,
            resolver: .live,
            context: .live,
            on: group
        ).wait()
         
        debugPrint(result)
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

