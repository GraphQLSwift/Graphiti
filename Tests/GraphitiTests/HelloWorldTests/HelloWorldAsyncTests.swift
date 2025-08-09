@testable import Graphiti
import GraphQL
import XCTest

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
let pubsub = SimplePubSub<User>()

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension HelloResolver {
    func asyncHello(
        context: HelloContext,
        arguments _: NoArguments
    ) async -> String {
        return await Task {
            context.hello()
        }.value
    }

    func subscribeUser(
        context _: HelloContext,
        arguments _: NoArguments
    ) async -> AsyncThrowingStream<User, Error> {
        await pubsub.subscribe()
    }

    func futureSubscribeUser(
        context _: HelloContext,
        arguments _: NoArguments
    ) async -> AsyncThrowingStream<User, Error> {
        await pubsub.subscribe()
    }

    func asyncSubscribeUser(
        context _: HelloContext,
        arguments _: NoArguments
    ) async -> AsyncThrowingStream<User, Error> {
        return await Task {
            await pubsub.subscribe()
        }.value
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
// Same as the HelloAPI, except with an async query and a few subscription fields
struct HelloAsyncAPI: API {
    typealias ContextType = HelloContext

    let resolver: HelloResolver = .init()
    let context: HelloContext = .init()

    let schema: Schema<HelloResolver, HelloContext> = try! Schema<HelloResolver, HelloContext> {
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
            SubscriptionField(
                "subscribeUser",
                as: User.self,
                atSub: HelloResolver.subscribeUser
            )
            SubscriptionField(
                "subscribeUserEvent",
                at: User.toEvent,
                atSub: HelloResolver.subscribeUser
            )

            SubscriptionField(
                "futureSubscribeUser",
                as: User.self,
                atSub: HelloResolver.subscribeUser
            )
            SubscriptionField(
                "asyncSubscribeUser",
                as: User.self,
                atSub: HelloResolver.asyncSubscribeUser
            )
        }
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
class HelloWorldAsyncTests: XCTestCase {
    private let api = HelloAsyncAPI()

    /// Tests that async version of API.execute works as expected
    func testAsyncExecute() async throws {
        let query = "{ hello }"
        let result = try await api.execute(
            request: query,
            context: api.context
        )
        XCTAssertEqual(
            result,
            GraphQLResult(data: ["hello": "world"])
        )
    }

    /// Tests that async fields (via ConcurrentResolve) are resolved successfully
    func testAsyncHello() async throws {
        let query = "{ asyncHello }"
        let result = try await api.execute(
            request: query,
            context: api.context
        )
        XCTAssertEqual(
            result,
            GraphQLResult(data: ["asyncHello": "world"])
        )
    }

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

        let subscription = try await api.subscribe(
            request: request,
            context: api.context
        ).get()
        var iterator = subscription.makeAsyncIterator()

        await pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

        let result = try await iterator.next()
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "subscribeUser": [
                    "id": "124",
                    "name": "Jerry",
                ],
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

        let subscription = try await api.subscribe(
            request: request,
            context: api.context
        ).get()
        var iterator = subscription.makeAsyncIterator()

        await pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

        let result = try await iterator.next()
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "subscribeUserEvent": [
                    "user": [
                        "id": "124",
                        "name": "Jerry",
                    ],
                ],
            ])
        )
    }

    /// Tests that subscription resolvers that return futures work
    func testFutureSubscription() async throws {
        let request = """
        subscription {
            futureSubscribeUser {
                id
                name
            }
        }
        """

        let subscription = try await api.subscribe(
            request: request,
            context: api.context
        ).get()
        var iterator = subscription.makeAsyncIterator()

        await pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

        let result = try await iterator.next()
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "futureSubscribeUser": [
                    "id": "124",
                    "name": "Jerry",
                ],
            ])
        )
    }

    /// Tests that subscription resolvers that are async work
    func testAsyncSubscription() async throws {
        let request = """
        subscription {
            asyncSubscribeUser {
                id
                name
            }
        }
        """

        let subscription = try await api.subscribe(
            request: request,
            context: api.context
        ).get()
        var iterator = subscription.makeAsyncIterator()

        await pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

        let result = try await iterator.next()
        XCTAssertEqual(
            result,
            GraphQLResult(data: [
                "asyncSubscribeUser": [
                    "id": "124",
                    "name": "Jerry",
                ],
            ])
        )
    }
}

/// A very simple publish/subscriber used for testing
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
actor SimplePubSub<T: Sendable>: Sendable {
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

    func subscribe() -> AsyncThrowingStream<T, Error> {
        return AsyncThrowingStream<T, Error> { continuation in
            let subscriber = Subscriber<T>(
                callback: { newValue in
                    continuation.yield(newValue)
                },
                cancel: {
                    continuation.finish()
                }
            )
            subscribers.append(subscriber)
        }
    }
}

struct Subscriber<T: Sendable> {
    let callback: (T) -> Void
    let cancel: () -> Void
}
