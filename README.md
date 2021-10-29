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

Add Graphiti to your `Package.swift`. Graphiti provides two important capabilities: building a type schema, and
serving queries against that type schema.

#### Defining entities

First, we declare our regular Swift entities. For our example, we are using the quintessential counter. The only requirements are that GraphQL output types must conform to `Encodable` and GraphQL input types must conform to `Decodable`.

```swift
struct Counter: Encodable {
    var count: Int
}
```

⭐️ Notice that this step does not require importing `Graphiti`. One of the main design decisions behind Graphiti is **not** to pollute your entities declarations. This way you can bring your entities to any other environment with ease.

#### Defining the context

Second step is to create your API's **context** actor. The context will be passed to all of your field resolver functions. This allows you to apply dependency injection to your API. This is the place where you can put code that derives your entities from a database or another service.

```swift
actor CounterContext {
    var counter: Counter
    
    init(counter: Counter) {
        self.counter = counter
    }
    
    func increment() -> Counter {
        counter.count += 1
        return counter
    }
    
    func decrement() -> Counter {
        counter.count -= 1
        return counter
    }
    
    func increment(by count: Int) -> Counter {
        counter.count += count
        return counter
    }
    
    func decrement(by count: Int) -> Counter {
        counter.count -= count
        return counter
    }
}
```

⭐️ Notice that this step does not require importing `Graphiti`. It is purely your API's business logic.

#### Defining the GraphQL API resolver

Now that we have our entities and context we can declare the GraphQL API resolver. These resolver functions will be used to resolve the queries and mutations defined in the schema.

```swift
struct CounterResolver {
    var counter: (CounterContext, Void) async throws -> Counter
    var increment: (CounterContext, Void) async throws -> Counter
    var decrement: (CounterContext, Void) async throws -> Counter
   
    struct IncrementByArguments: Decodable {
        let count: Int
    }
    
    var incrementBy: (CounterContext, IncrementByArguments) async throws -> Counter
    
    struct DecrementByArguments: Decodable {
        let count: Int
    }
    
    var decrementBy: (CounterContext, DecrementByArguments) async throws -> Counter
}
```

⭐️ Notice that this step does not require importing `Graphiti`. However, all resolver functions must take the following shape:

```swift
(Context, Arguments) async thows -> Output where Arguments: Decodable, Output: Encodable
```

In case your resolve function does not use any arguments you can use the following shape:


```swift
(Context, Void) async thows -> Output where Output: Encodable
```

#### Defining the GraphQL API schema

Now we can finally define the GraphQL API with its schema.

```swift
import Graphiti

struct CounterAPI {
    let schema = Schema<CounterResolver, CounterContext> {
        Type(Counter.self) {
            Field("count", at: \.count)
        }
        
        Query {
            Field("counter", at: \.counter)
        }

        Mutation {
            Field("increment", at: \.increment)
            Field("decrement", at: \.decrement)
            
            Field("incrementBy", at: \.incrementBy) {
                Argument("count", at: \.count)
            }
            
            Field("decrementBy", at: \.decrementBy) {
                Argument("count", at: \.count)
            }
        }
    }
}
```

⭐️ Now we finally import Graphiti. Notice that `Schema` allows dependency injection. You could pass mocks of `resolver` and `context` to `Schema.execute` when testing, for example.

#### Querying

To query the schema, we first need to create a live instance of the context:

```swift
extension CounterContext {
    static let live = CounterContext(counter: Counter(count: 0))
}
```

Now we create a live instance of the resolver:

```swift
extension CounterResolver {
    static let live = CounterResolver(
        counter: { context, _ in
            await context.counter
        },
        increment: { context, _ in
            await context.increment()
        },
        decrement: { context, _ in
            await context.decrement()
        },
        incrementBy: { context, arguments in
            await context.increment(by: arguments.count)
        },
        decrementBy: { context, arguments in
            await context.decrement(by: arguments.count)
        }
    )
}
```

This implementation basically extracts the arguments from the GraphQL query and delegates the business logic to the `context`. As mentioned before, you could create a `test` version of the context and the resolver when testing. Now we just need an `EventLoopGroup` from `NIO` and we're ready to query the API.

```swift
import NIO

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
defer {
    try? group.syncShutdownGracefully()
}

let api = CounterAPI()

let countQuery = """
query {
  counter {
    count
  }
}
"""

let countResult = try await api.schema.execute(
    request: countQuery,
    resolver: .live,
    context: .live,
    on: group
)

debugPrint(countResult)
```

The output will be:

```json
{
  "data" : {
    "counter" : {
      "count" : 0
    }
  }
}
```

For the increment mutation:

```swift
let incrementMutation = """
mutation {
  increment {
    count
  }
}
"""

let incrementResult = try await api.schema.execute(
    request: incrementMutation,
    resolver: .live,
    context: .live,
    on: group
)

debugPrint(incrementResult)
```

The output will be:

```json
{
  "data" : {
    "increment" : {
      "count" : 1
    }
  }
}
```

For the decrement mutation:

```swift
let decrementMutation = """
mutation {
  decrement {
    count
  }
}
"""

let decrementResult = try await api.schema.execute(
    request: decrementMutation,
    resolver: .live,
    context: .live,
    on: group
)

debugPrint(decrementResult)
```

The output will be:

```json
{
  "data" : {
    "decrement" : {
      "count" : 0
    }
  }
}
```

For the incrementBy mutation:

```swift
let incrementByMutation = """
mutation {
  incrementBy(count: 5) {
    count
  }
}
"""

let incrementByResult = try await api.schema.execute(
    request: incrementByMutation,
    resolver: .live,
    context: .live,
    on: group
)

debugPrint(incrementByResult)
```

The output will be:

```json
{
  "data" : {
    "incrementBy" : {
      "count" : 5
    }
  }
}
```

For the decrementBy mutation:

```swift
let decrementByMutation = """
mutation {
  decrementBy(count: 5) {
    count
  }
}
"""

let decrementByResult = try await api.schema.execute(
    request: decrementByMutation,
    resolver: .live,
    context: .live,
    on: group
)

debugPrint(decrementByResult)
```

The output will be:

```json
{
  "data" : {
    "decrementBy" : {
      "count" : 0
    }
  }
}
```

⭐️ `Schema.execute` returns a `GraphQLResult` which adopts `Encodable`. You can use it with a `JSONEncoder` to send the response back to the client using JSON.

#### Subscription

This library supports GraphQL subscriptions. To use them, you must create a concrete subclass of the `EventStream` class that implements event streaming
functionality.

If you don't feel like creating a subclass yourself, you can use the [GraphQLRxSwift](https://github.com/GraphQLSwift/GraphQLRxSwift) repository
to integrate [RxSwift](https://github.com/ReactiveX/RxSwift) observables out-of-the-box. Or you can use that repository as a reference to connect a different 
stream library like [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift), [OpenCombine](https://github.com/OpenCombine/OpenCombine), or
one that you've created yourself.

## Star Wars API example

Check the [Star Wars API](Tests/GraphitiTests/StarWarsAPI/StarWarsAPI.swift) for a more complete example.

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

