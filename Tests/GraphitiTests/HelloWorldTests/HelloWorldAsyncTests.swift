// @testable import Graphiti
// import GraphQL
// import Testing

// @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
// struct AsyncHelloResolver: Sendable {
//     func hello(context: AsyncHelloContext, arguments _: NoArguments) -> String {
//         context.hello()
//     }

//     func futureHello(
//         context: AsyncHelloContext,
//         arguments _: NoArguments
//     ) -> String {
//         context.hello()
//     }

//     struct FloatArguments: Codable {
//         let float: Float
//     }

//     func getFloat(context _: AsyncHelloContext, arguments: FloatArguments) -> Float {
//         arguments.float
//     }

//     struct IDArguments: Codable {
//         let id: ID
//     }

//     func getId(context _: AsyncHelloContext, arguments: IDArguments) -> ID {
//         arguments.id
//     }

//     func getUser(context _: AsyncHelloContext, arguments _: NoArguments) -> User {
//         User(id: "123", name: "John Doe", friends: nil)
//     }

//     struct AddUserArguments: Codable {
//         let user: UserInput
//     }

//     func addUser(context _: AsyncHelloContext, arguments: AddUserArguments) -> User {
//         User(arguments.user)
//     }

//     func asyncHello(
//         context: AsyncHelloContext,
//         arguments _: NoArguments
//     ) async -> String {
//         return await Task {
//             context.hello()
//         }.value
//     }

//     func subscribeUser(
//         context: AsyncHelloContext,
//         arguments _: NoArguments
//     ) async -> AsyncThrowingStream<User, Error> {
//         await context.pubsub.subscribe()
//     }

//     func futureSubscribeUser(
//         context: AsyncHelloContext,
//         arguments _: NoArguments
//     ) async -> AsyncThrowingStream<User, Error> {
//         await context.pubsub.subscribe()
//     }

//     func asyncSubscribeUser(
//         context: AsyncHelloContext,
//         arguments _: NoArguments
//     ) async -> AsyncThrowingStream<User, Error> {
//         return await Task {
//             await context.pubsub.subscribe()
//         }.value
//     }
// }

// final class AsyncHelloContext: Sendable {
//     let pubsub = SimplePubSub<User>()

//     func hello() -> String {
//         "world"
//     }
// }

// extension User {
//     func toEvent(context _: AsyncHelloContext, arguments _: NoArguments) throws -> UserEvent {
//         return UserEvent(user: self)
//     }
// }

// @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
// struct HelloAsyncAPI: API {
//     let resolver: AsyncHelloResolver = .init()

//     let schema: Schema<AsyncHelloResolver, AsyncHelloContext> = try! Schema<AsyncHelloResolver, AsyncHelloContext> {
//         Scalar(Float.self)
//             .description(
//                 "The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)."
//             )

//         Scalar(ID.self)
//             .description("The `ID` scalar type represents a unique identifier.")

//         Type(User.self) {
//             Field("id", at: \.id)
//             Field("name", at: \.name)
//             Field("friends", at: \.friends)
//         }

//         Input(UserInput.self) {
//             InputField("id", at: \.id)
//             InputField("name", at: \.name)
//             InputField("friends", at: \.friends)
//         }

//         Type(UserEvent.self) {
//             Field("user", at: \.user)
//         }

//         Query {
//             Field("hello", at: AsyncHelloResolver.hello)
//             Field("futureHello", at: AsyncHelloResolver.futureHello)
//             Field("asyncHello", at: AsyncHelloResolver.asyncHello)

//             Field("float", at: AsyncHelloResolver.getFloat) {
//                 Argument("float", at: \.float)
//             }

//             Field("id", at: AsyncHelloResolver.getId) {
//                 Argument("id", at: \.id)
//             }

//             Field("user", at: AsyncHelloResolver.getUser)
//         }

//         Mutation {
//             Field("addUser", at: AsyncHelloResolver.addUser) {
//                 Argument("user", at: \.user)
//             }
//         }

//         Subscription {
//             SubscriptionField(
//                 "subscribeUser",
//                 as: User.self,
//                 atSub: AsyncHelloResolver.subscribeUser
//             )
//             SubscriptionField(
//                 "subscribeUserEvent",
//                 at: User.toEvent,
//                 atSub: AsyncHelloResolver.subscribeUser
//             )

//             SubscriptionField(
//                 "futureSubscribeUser",
//                 as: User.self,
//                 atSub: AsyncHelloResolver.subscribeUser
//             )
//             SubscriptionField(
//                 "asyncSubscribeUser",
//                 as: User.self,
//                 atSub: AsyncHelloResolver.asyncSubscribeUser
//             )
//         }
//     }
// }

// struct HelloWorldAsyncTests {
//     private let api = HelloAsyncAPI()

//     /// Tests that async version of API.execute works as expected
//     @Test
//     @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
//     func asyncExecute() async throws {
//         let context = AsyncHelloContext()
//         let query = "{ hello }"
//         let result = try await api.execute(
//             request: query,
//             context: context
//         )
//         #expect(result == GraphQLResult(data: ["hello": "world"]))
//     }

//     /// Tests that async fields (via ConcurrentResolve) are resolved successfully
//     @Test
//     @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
//     func asyncHello() async throws {
//         let context = AsyncHelloContext()
//         let query = "{ asyncHello }"
//         let result = try await api.execute(
//             request: query,
//             context: context
//         )
//         #expect(result == GraphQLResult(data: ["asyncHello": "world"]))
//     }

//     /// Tests subscription when the sourceEventStream type matches the resolved type (i.e. the normal resolution function should just short-circuit to the sourceEventStream object)
//     @Test
//     @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
//     func subscriptionSelf() async throws {
//         let context = AsyncHelloContext()
//         let request = """
//         subscription {
//             subscribeUser {
//                 id
//                 name
//             }
//         }
//         """

//         let subscription = try await api.subscribe(
//             request: request,
//             context: context
//         ).get()
//         var iterator = subscription.makeAsyncIterator()

//         await context.pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

//         let result = try await iterator.next()
//         #expect(
//             result ==
//             GraphQLResult(data: [
//                 "subscribeUser": [
//                     "id": "124",
//                     "name": "Jerry",
//                 ],
//             ])
//         )
//     }

//     /// Tests subscription when the sourceEventStream type does not match the resolved type (i.e. there is a non-trivial resolution function that transforms the sourceEventStream object)
//     @Test
//     @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
//     func subscriptionEvent() async throws {
//         let context = AsyncHelloContext()
//         let request = """
//         subscription {
//             subscribeUserEvent {
//                 user {
//                     id
//                     name
//                 }
//             }
//         }
//         """

//         let subscription = try await api.subscribe(
//             request: request,
//             context: context
//         ).get()
//         var iterator = subscription.makeAsyncIterator()

//         await context.pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

//         let result = try await iterator.next()
//         #expect(
//             result ==
//             GraphQLResult(data: [
//                 "subscribeUserEvent": [
//                     "user": [
//                         "id": "124",
//                         "name": "Jerry",
//                     ],
//                 ],
//             ])
//         )
//     }

//     /// Tests that subscription resolvers that return futures work
//     @Test
//     @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
//     func futureSubscription() async throws {
//         let context = AsyncHelloContext()
//         let request = """
//         subscription {
//             futureSubscribeUser {
//                 id
//                 name
//             }
//         }
//         """

//         let subscription = try await api.subscribe(
//             request: request,
//             context: context
//         ).get()
//         var iterator = subscription.makeAsyncIterator()

//         await context.pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

//         let result = try await iterator.next()
//         #expect(
//             result ==
//             GraphQLResult(data: [
//                 "futureSubscribeUser": [
//                     "id": "124",
//                     "name": "Jerry",
//                 ],
//             ])
//         )
//     }

//     /// Tests that subscription resolvers that are async work
//     @Test
//     @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
//     func asyncSubscription() async throws {
//         let context = AsyncHelloContext()
//         let request = """
//         subscription {
//             asyncSubscribeUser {
//                 id
//                 name
//             }
//         }
//         """

//         let subscription = try await api.subscribe(
//             request: request,
//             context: context
//         ).get()
//         var iterator = subscription.makeAsyncIterator()

//         await context.pubsub.publish(event: User(id: "124", name: "Jerry", friends: nil))

//         let result = try await iterator.next()
//         #expect(
//             result ==
//             GraphQLResult(data: [
//                 "asyncSubscribeUser": [
//                     "id": "124",
//                     "name": "Jerry",
//                 ],
//             ])
//         )
//     }
// }

// /// A very simple publish/subscriber used for testing
// @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
// actor SimplePubSub<T: Sendable>: Sendable {
//     private var subscribers: [Subscriber<T>]

//     init() {
//         subscribers = []
//     }

//     func publish(event: T) {
//         for subscriber in subscribers {
//             subscriber.callback(event)
//         }
//     }

//     func cancel() {
//         for subscriber in subscribers {
//             subscriber.cancel()
//         }
//     }

//     func subscribe() -> AsyncThrowingStream<T, Error> {
//         return AsyncThrowingStream<T, Error> { continuation in
//             let subscriber = Subscriber<T>(
//                 callback: { newValue in
//                     continuation.yield(newValue)
//                 },
//                 cancel: {
//                     continuation.finish()
//                 }
//             )
//             subscribers.append(subscriber)
//         }
//     }
// }

// struct Subscriber<T: Sendable> {
//     let callback: (T) -> Void
//     let cancel: () -> Void
// }
