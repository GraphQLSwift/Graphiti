# Graphiti

Graphiti is a Swift library for building GraphQL schemas fast, safely and easily.

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![GitHub Actions][gh-actions-badge]][gh-actions-url]
[![Maintainability][maintainability-badge]][maintainability-url]
[![Coverage][coverage-badge]][coverage-url]

Looking for help? Find resources [from the community](http://graphql.org/community/).


## Getting Started

An overview of GraphQL in general is available in the
[README](https://github.com/facebook/graphql/blob/master/README.md) for the
[Specification for GraphQL](https://github.com/facebook/graphql). That overview
describes a simple set of GraphQL examples that exist as [tests](Tests/GraphitiTests/StarWarsTests/)
in this repository. A good way to get started with this repository is to walk
through that README and the corresponding tests in parallel.

### Using Graphiti

Add Graphiti to your `Package.swift`

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", .upToNextMinor(from: "0.20.1")),
    ]
)
```

Graphiti provides two important capabilities: building a type schema, and
serving queries against that type schema.

#### Defining entities

First, we declare our regular Swift entities.

```swift
struct Message : Codable {
    let content: String
}
```

⭐️ One of the main design decisions behind Graphiti is **not** to polute your entities declarations. This way you can bring your entities to any other solution with ease.

#### Defining the context

Second step is to create your application's **context**. The context will be passed to all of your field resolver functions. This allows you to apply dependency injection to your API. This is the place where you can put code that talks to a database or another service.

```swift
struct Context {
    func message() -> Message {
        Message(content: "Hello, world!")
    }
}
```

⭐️ Notice again that this step doesn't require Graphiti. It's purely business logic.

#### Defining the GraphQL API resolver

Now that we have our entities and context we can create the GraphQL API resolver.

```swift
import Graphiti

struct Resolver {
    func message(context: Context, arguments: NoArguments) -> Message {
        context.message()
    }
}
```

#### Defining the GraphQL API schema

Now we can finally define the GraphQL API with its schema.

```swift
struct MessageAPI : API {
    let resolver: Resolver
    let schema: Schema<Resolver, Context>
}

let api = MessageAPI(
    resolver: Resolver()
    schema: try! Schema<Resolver, Context> {
        Type(Message.self) {
            Field("content", at: \.content)
        }

        Query {
            Field("message", at: Resolver.message)
        }
    }
)
```

Schemas may also be created in a modular way using `SchemaBuilder`:

<blockquote>

<details open="true">
<summary>SchemaBuilder API</summary>

```swift
let builder = SchemaBuilder(Resolver.self, Context.self)
builder.add(
    Type(Message.self) {
        Field("content", at: \.content)
    }
)
builder.query.add(
    Field("message", at: Resolver.message)
)
let schema = try builder.build()

let api = MessageAPI(
    resolver: Resolver()
    schema: schema
)
```

</details>
<details>
<summary>PartialSchema implementation</summary>

```swift
final class ChatSchema: PartialSchema<Resolver, Context> {
    @TypeDefinitions
    public override var types: Types {
        Type(Message.self) {
            Field("content", at: \.content)
        }
    }

    @FieldDefinitions
    public override var query: Fields {
        Field("message", at: Resolver.message)
    }
}
let schema = try SchemaBuilder(Resolver.self, Context.self)
    .use(partials: [ChatSchema(), ...])
    .build()

let api = MessageAPI(
    resolver: Resolver()
    schema: schema
)
```

</details>

<details>
<summary>PartialSchema instance</summary>

```swift
let chatSchema = PartialSchema<Resolver, Context>(
    types:  {
        Type(Message.self) {
            Field("content", at: \.content)
        }
    },
    query: {
        Field("message", at: Resolver.message)
    }
)
let schema = try SchemaBuilder(Resolver.self, Context.self)
    .use(partials: [chatSchema, ...])
    .build()

let api = MessageAPI(
    resolver: Resolver()
    schema: schema
)
```

</details>

---

</blockquote>

⭐️ Notice that `API` allows dependency injection. You could pass mocks of `resolver` and `context` when testing, for example.

#### Querying

```swift
let result = try await api.execute(
    request: "{ message { content } }",
    context: Context()
)
print(result)
```

The output will be:

```json
{"data":{"message":{"content":"Hello, world!"}}}
```

`API.execute` returns a `GraphQLResult` which adopts `Encodable`. You can use it with a `JSONEncoder` to send the response back to the client using JSON.

#### Async resolvers

Resolver functions can also be `async`:

```swift
struct Resolver {
    func message(context: Context, arguments: NoArguments) async -> Message {
        await someAsyncMethodToGetMessage()
    }
}
```

#### Subscription

This library supports GraphQL subscriptions, and supports them through the Swift Concurrency `AsyncThrowingStream` type. See the [Usage Guide](UsageGuide.md#subscriptions) for details.

If you are unable to use Swift Concurrency, you must create a concrete subclass of the `EventStream` class that implements event streaming
functionality. If you don't feel like creating a subclass yourself, you can use the [GraphQLRxSwift](https://github.com/GraphQLSwift/GraphQLRxSwift) repository
to integrate [RxSwift](https://github.com/ReactiveX/RxSwift) observables out-of-the-box. Or you can use that repository as a reference to connect a different
stream library like [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift), [OpenCombine](https://github.com/OpenCombine/OpenCombine), or
one that you've created yourself.

## Additional Examples

For a progressive walkthrough, see the [Usage Guide](UsageGuide.md). The [Star Wars API](Tests/GraphitiTests/StarWarsAPI/StarWarsAPI.swift) provides a fairly complete example.

## Support

This package supports Swift versions in [alignment with Swift NIO](https://github.com/apple/swift-nio?tab=readme-ov-file#swift-versions).

## Contributing

This repo uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat), and includes lint checks to enforce these formatting standards.
To format your code, install `swiftformat` and run:

```bash
swiftformat .
```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-5.4-orange.svg?style=flat
[swift-url]: https://swift.org

[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license

[gh-actions-badge]: https://github.com/GraphQLSwift/Graphiti/workflows/Tests/badge.svg
[gh-actions-url]: https://github.com/GraphQLSwift/Graphiti/actions?query=workflow%3ATests

[maintainability-badge]: https://api.codeclimate.com/v1/badges/25559824033fc2caa94e/maintainability
[maintainability-url]: https://codeclimate.com/github/GraphQLSwift/Graphiti/maintainability

[coverage-badge]: https://api.codeclimate.com/v1/badges/25559824033fc2caa94e/test_coverage
[coverage-url]: https://codeclimate.com/github/GraphQLSwift/Graphiti/test_coverage
