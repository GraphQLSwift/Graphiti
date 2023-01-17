@testable import Graphiti
import GraphQL
import NIO
import XCTest

#if compiler(>=5.5) && canImport(_Concurrency)

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

        func subscribeUser(context _: HelloContext, arguments _: NoArguments) -> EventStream<User> {
            pubsub.subscribe()
        }

        func futureSubscribeUser(
            context _: HelloContext,
            arguments _: NoArguments,
            group: EventLoopGroup
        ) -> EventLoopFuture<EventStream<User>> {
            group.next().makeSucceededFuture(pubsub.subscribe())
        }

        func asyncSubscribeUser(
            context _: HelloContext,
            arguments _: NoArguments
        ) async -> EventStream<User> {
            return await Task {
                pubsub.subscribe()
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
        private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        /// Tests that async version of API.execute works as expected
        func testAsyncExecute() async throws {
            let query = "{ hello }"
            let result = try await api.execute(
                request: query,
                context: api.context,
                on: group
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
                context: api.context,
                on: group
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

            let subscriptionResult = try await api.subscribe(
                request: request,
                context: api.context,
                on: group
            )
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

            let subscriptionResult = try await api.subscribe(
                request: request,
                context: api.context,
                on: group
            )
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

            let subscriptionResult = try await api.subscribe(
                request: request,
                context: api.context,
                on: group
            )
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
                    "asyncSubscribeUser": [
                        "id": "124",
                        "name": "Jerry",
                    ],
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
            }
            return ConcurrentEventStream<T>.init(asyncStream)
        }
    }

    struct Subscriber<T> {
        let callback: (T) -> Void
        let cancel: () -> Void
    }

#endif
