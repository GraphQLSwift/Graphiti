# Migration

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