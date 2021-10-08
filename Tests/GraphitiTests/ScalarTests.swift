import XCTest
import GraphQL
import Foundation
import NIO
@testable import Graphiti

class ScalarTests : XCTestCase {
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    func testDateOutput() throws {
        struct DateOutput : Codable {
            let value: Date
        }
        
        struct TestResolver {
            func date(context: NoContext, arguments: NoArguments) -> DateOutput {
                return DateOutput(value: Date.init(timeIntervalSinceReferenceDate: 0))
            }
        }
        
        let coders = Coders()
        coders.decoder.dateDecodingStrategy = .iso8601
        coders.encoder.dateEncodingStrategy = .iso8601
        let testSchema = try Schema<TestResolver, NoContext>(
            coders: coders
        ) {
            DateScalar(as: "Date", formatter: ISO8601DateFormatter())
            Type(DateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("date", at: TestResolver.date)
            }
        }
        let api = TestAPI<TestResolver, NoContext> (
            resolver: TestResolver(),
            schema: testSchema
        )
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }
        
        XCTAssertEqual(
            try? api.execute(
                request: """
                query {
                  date {
                    value
                  }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "date": [
                    "value": "2001-01-01T00:00:00Z"
                ]
            ])
        )
    }
    
    func testDateArg() throws {
        struct DateOutput : Codable {
            let value: Date
        }
        
        struct Arguments : Codable {
            let value: Date
        }
        
        struct TestResolver {
            func date(context: NoContext, arguments: Arguments) -> DateOutput {
                return DateOutput(value: arguments.value)
            }
        }
        
        let coders = Coders()
        coders.decoder.dateDecodingStrategy = .iso8601
        coders.encoder.dateEncodingStrategy = .iso8601
        let testSchema = try Schema<TestResolver, NoContext>(
            coders: coders
        ) {
            DateScalar(as: "Date", formatter: ISO8601DateFormatter())
            Type(DateOutput.self) {
                Field("value", at: \.value)
            }
            Query {
                Field("date", at: TestResolver.date) {
                    Argument("value", at: \.value)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext> (
            resolver: TestResolver(),
            schema: testSchema
        )
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }
        
        XCTAssertEqual(
            try? api.execute(
                request: """
                query {
                  date (value: "2001-01-01T00:00:00Z") {
                    value
                  }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "date": [
                    "value": "2001-01-01T00:00:00Z"
                ]
            ])
        )
    }
    
    func testDateInput() throws {
        struct DateOutput : Codable {
            let value: Date
        }
        
        struct DateInput : Codable {
            let value: Date
        }
        
        struct Arguments : Codable {
            let input: DateInput
        }
        
        struct TestResolver {
            func date(context: NoContext, arguments: Arguments) -> DateOutput {
                return DateOutput(value: arguments.input.value)
            }
        }
        
        let coders = Coders()
        coders.decoder.dateDecodingStrategy = .iso8601
        coders.encoder.dateEncodingStrategy = .iso8601
        let testSchema = try Schema<TestResolver, NoContext>(
            coders: coders
        ) {
            DateScalar(as: "Date", formatter: ISO8601DateFormatter())
            Type(DateOutput.self) {
                Field("value", at: \.value)
            }
            Input(DateInput.self) {
                InputField("value", at: \.value)
            }
            Query {
                Field("date", at: TestResolver.date) {
                    Argument("input", at: \.input)
                }
            }
        }
        let api = TestAPI<TestResolver, NoContext> (
            resolver: TestResolver(),
            schema: testSchema
        )
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }
        
        XCTAssertEqual(
            try? api.execute(
                request: """
                query {
                  date (input: {value: "2001-01-01T00:00:00Z"}) {
                    value
                  }
                }
                """,
                context: NoContext(),
                on: group
            ).wait(),
            GraphQLResult(data: [
                "date": [
                    "value": "2001-01-01T00:00:00Z"
                ]
            ])
        )
    }
}

fileprivate class TestAPI<Resolver, ContextType> : API {
    public let resolver: Resolver
    public let schema: Schema<Resolver, ContextType>
    
    init(resolver: Resolver, schema: Schema<Resolver, ContextType>) {
        self.resolver = resolver
        self.schema = schema
    }
}
