# Graphiti 

Graphiti is a Swift library for building GraphQL schemas fast, safely and easily.

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
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
        .Package(url: "https://github.com/GraphQLSwift/Graphiti.git", .upToNextMinor(from: "0.20.1")),
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
    
    init(resolver: Resolver) throws {
        self.resolver = resolver

        self.schema = try Schema<Resolver, Context> {
            Type(Message.self) {
                Field("content", at: \.content)
            }

            Query {
                Field("message", at: Resolver.message)
            }
        }
    }
}
```

⭐️ Notice that `API` allows dependency injection. You could pass mocks of `resolver` and `context` when testing, for example.

#### Querying

To query the schema we need to instantiate the api and pass in an EventLoopGroup to feed the execute function alongside the query itself.

```swift
import NIO

let resolver = Resolver()
let context = Context()
let api = try MessageAPI(resolver: resolver)
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
defer {
    try? group.syncShutdownGracefully()
}

api.execute(
    request: "{ message { content } }",
    context: context,
    on: group
).whenSuccess { result in
    print(result)
}
```

The output will be:

```json
{"data":{"message":{"content":"Hello, world!"}}}
```

`API.execute` returns a `GraphQLResult` which adopts `Encodable`. You can use it with a `JSONEncoder` to send the response back to the client using JSON.

#### Async resolvers

To use async resolvers, just add one more parameter with type `EventLoopGroup` to the resolver function and change the return type to `EventLoopFuture<YouReturnType>`. Don't forget to import NIO.

```swift
import NIO

struct Resolver {
    func message(context: Context, arguments: NoArguments, group: EventLoopGroup) -> EventLoopFuture<Message> {
        group.next().makeSucceededFuture(context.message())
    }
}
```

#### Subscription

This library supports GraphQL subscriptions. To use them, you must create a concrete subclass of the `EventStream` class that implements event streaming
functionality.

If you don't feel like creating a subclass yourself, you can use the [GraphQLRxSwift](https://github.com/GraphQLSwift/GraphQLRxSwift) repository
to integrate [RxSwift](https://github.com/ReactiveX/RxSwift) observables out-of-the-box. Or you can use that repository as a reference to connect a different 
stream library like [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift), [OpenCombine](https://github.com/OpenCombine/OpenCombine), or
one that you've created yourself.

## Star Wars API example

Check the [Star Wars API](Tests/GraphitiTests/StarWarsAPI/StarWarsAPI.swift) for a more complete example.

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

[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io

[gh-actions-badge]: https://github.com/GraphQLSwift/Graphiti/workflows/Tests/badge.svg
[gh-actions-url]: https://github.com/GraphQLSwift/Graphiti/actions?query=workflow%3ATests

[maintainability-badge]: https://api.codeclimate.com/v1/badges/25559824033fc2caa94e/maintainability
[maintainability-url]: https://codeclimate.com/github/GraphQLSwift/Graphiti/maintainability

[coverage-badge]: https://api.codeclimate.com/v1/badges/25559824033fc2caa94e/test_coverage
[coverage-url]: https://codeclimate.com/github/GraphQLSwift/Graphiti/test_coverage
