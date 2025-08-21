# Migration

## 2.0 to 3.0

### NIO removal

All NIO-based parameters and return types were removed, including all that used `EventLoopGroup` and `EventLoopFuture`s.

As such, all `API.execute` and `API.subscribe` calls should have the `eventLoopGroup` argument removed, and the `await` keyword should be used. If access to an `eventLoopGroup` is required in the resolver, one should be passed via the `Context`.

Also, all resolver closures have had the `eventLoopGroup` parameter removed, and all that return an `EventLoopFuture` should be converted to an `async` function.

The documentation here may be very helpful in the conversion: https://www.swift.org/documentation/server/guides/libraries/concurrency-adoption-guidelines.html

### Swift Concurrency checking

With the conversion from NIO to Swift Concurrency, types used across async boundaries should conform to `Sendable` to avoid errors and warnings. This includes the Swift types and functions that back the GraphQL schema, including the `Resolver` and `Context` types. For more details on the conversion, see the [Sendable documentation](https://developer.apple.com/documentation/swift/sendable).

### Subscription result changes

The `API.subscribe(...)` will return a `Result<AsyncThrowingStream<GraphQLResult, Error>>`, instead of an `EventStream`. This means extracting the stream via a `.stream` call and downcasting to `ConcurrentEventStream` are no longer necessary.
The `EventStream` and `SubscriptionResult` types have been removed.

### GraphQL v4 upgrades

See [the GraphQL v4 migration documentation](https://github.com/GraphQLSwift/GraphQL/blob/main/MIGRATION.md#3-to-4) for additional details.

## 1.0 to 2.0

### TypeReference removal

The `TypeReference` type was removed in v2.0.0, since it was made unnecessary when using the [GraphQL](https://github.com/GraphQLSwift/GraphQL)  closure-based `field` API. Simply replace any `TypeReference` usage with the actual type:

```swift
// Before
let schema = try! Schema<HelloResolver, HelloContext> {
    Type(Object1.self) { }
    Type(Object2.self) {
        Field("object1", at: \.object1, as: TypeReference<Object1>.self)
    }
}

// After
let schema = try! Schema<HelloResolver, HelloContext> {
    Type(Object1.self) { }
    Type(Object2.self) {
        Field("object1", at: \.object1)
    }
}
```

### Field/InputField `as` argument removal

Since TypeReference was removed, there is no longer a functional need for the `as` argument on `Field` and `InputField`
types. To remove it, simply omit it and let the compiler determine the type from the signature of the `at` argument.

### `Types` removal

The deprecated `Types` type has been removed. Instead define types individually using the `Type` initializers.

### Reflection `isEncodable`

The deprecated `Reflection.isEncodable(type: Any.Type) -> Bool` function has been removed. Please re-implement in your
package if this functionality is needed.
