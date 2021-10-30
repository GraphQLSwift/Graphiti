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

### Defining entities

First, we create our regular Swift entities. For our example, we are using the quintessential counter. The only requirements are that GraphQL output types must conform to `Encodable` and GraphQL input types must conform to `Decodable`.

```swift
struct Count: Encodable {
    var value: Int
}
```

⭐️ Notice that this step does not require importing `Graphiti`. One of the main design decisions behind Graphiti is to **not** pollute your entities declarations. This way you can bring your entities to any other environment with ease.

#### Defining the business logic

Then, we create the business logic of our API. The best suited type for this is an actor. Within this actor we define our state and all the different ways this state can be accessed and updated. This is the place where you put code that derives your entities from a database or any other service. You have complete design freedom here.

```swift
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
```

#### Defining the context

Third step is to create the GraphQL API context. The context will be passed to all of your field resolver functions. This allows you to apply dependency injection to your API. The context's role is  to give the GraphQL resolvers access to your APIs business logic. 

```swift
struct CounterContext {
    var count: () async -> Count
    var increment: () async -> Count
    var decrement: () async -> Count
    var incrementBy: (_ amount: Int) async -> Count
    var decrementBy: (_ amount: Int) async -> Count
}
```

You can model the context however you like. You could bypass the creation of a separate type and use your APIs actor directly as the GraphQL context. However, we do not encourage this, since it makes your API less testable. You could, for example, use a delegate protocol that would allow you to have different implementations in different environments. Nonetheless, we prefer structs with mutable closure properties, because we can easily create different versions of a context by swapping specific closures, instead of having to create a complete type conforming to a delegate protocol every time we need a new behavior. With this design we can easily create a mocked version of our context when testing, for example. 

#### Defining the GraphQL API resolver

Now we can create the GraphQL API root resolver. These root resolver functions will be used to resolve the queries and mutations defined in the schema.

```swift
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
```

⭐️ Notice that this step does not require importing `Graphiti`. However, all resolver functions must take the following shape:

```swift
(Context, Arguments) async throws -> Output where Arguments: Decodable
```

In case your resolve function does not use any arguments you can use the following shape:


```swift
(Context, Void) async throws -> Output
```

Our `CounterResolver` looks very similar to our `CounterContext`. First thing we notice is that we're using a struct with mutable closure properties again. We do this for the same reason we do it for `CounterContext`. To allow us to easily swap implementations in different environments. The closures themselves are also almost identical. The difference is that resolver functions need to follow the specific shapes we mentioned above. We do it this way because `Graphiti` needs a predictable structure to be able to decode arguments and execute the resolver function. Most of the time, the resolver function's role is to extract the parameters and forward the business logic to the context.

Notice too that in this example there's a one-to-one mapping of the context's properties and the resolver's properties. This only happens for small applications. In a complex application, the root resolver might map to only a subset of the context's properties, because the context might contain additional logic that could be accessed by other resolver functions defined in custom GraphQL types, for example.

#### Defining the GraphQL API schema

At last, we define the GraphQL API with its schema.

```swift
import Graphiti

struct CounterAPI {
    let schema = Schema<CounterResolver, CounterContext> {
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
```

⭐️ Now we finally need to import Graphiti. 😄

#### Querying

To query the schema, we first need to create a live instance of the context:

```swift
extension CounterContext {
    static let live: CounterContext = {
        let count = Count(value: 0)
        let application = CounterState(count: count)
        
        return CounterContext(
            count: {
                await application.count
            },
            increment: {
                await application.increment()
            },
            decrement: {
                await application.decrement()
            },
            incrementBy: { count in
                await application.increment(by: count)
            },
            decrementBy: { count in
                await application.decrement(by: count)
            }
        )
    }()
}
```

Now we create a live instance of the resolver:

```swift
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
  count {
    value
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
    "count" : {
      "value" : 0
    }
  }
}
```

For the increment mutation:

```swift
let incrementMutation = """
mutation {
  increment {
    value
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
      "value" : 1
    }
  }
}
```

For the decrement mutation:

```swift
let decrementMutation = """
mutation {
  decrement {
    value
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
      "value" : 0
    }
  }
}
```

For the incrementBy mutation:

```swift
let incrementByMutation = """
mutation {
  incrementBy(count: 5) {
    value
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
      "value" : 5
    }
  }
}
```

For the decrementBy mutation:

```swift
let decrementByMutation = """
mutation {
  decrementBy(count: 5) {
    value
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
      "value" : 0
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

