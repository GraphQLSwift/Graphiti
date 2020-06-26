# Graphiti 

Graphiti is a Swift library for building GraphQL schemas/types fast, safely and easily.

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codecov][codecov-badge]][codecov-url]
[![Codebeat][codebeat-badge]][codebeat-url]

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
        .Package(url: "https://github.com/GraphQLSwift/Graphiti.git", .upToNextMinor(from: "0.13.3")),
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

One of the main design decisions behind Graphiti is **not** to polute your entities declarations. This way you can bring your entities to any other solution with ease.

#### Defining the context

Second step is to create your application's **context**. The context will be passed to all of your field resolver functions. This allows you to apply dependency injection to your API. You will usually use the Context as the state holder of your API. Therefore, this will often be a `class`. We're calling it a store here, because that's the only thing that it does, but you should name it in a way that is appropriate to what your context does.

```swift
/**
 * This data is hard coded for the sake of the demo, but you could imagine
 * fetching this data from a database or a backend service instead.
 */
final class MessageStore {
    func getMessage() -> Message {
        Message(content: "Hello, world!")
    }
}
```

Notice again that this step doesn't require Graphiti. It's purely business logic.

#### Defining the API implementation

Now that we have our entities and context we can create the API itself.

```swift
import Graphiti

// We make Message adopt Keyable so we can 
// provide keys to be used in the schema.
// This allows you to have different names between 
// your properties and the fields you expose in the schema.
extension Message : Keyable {
    enum Keys : String {
        case content
    }
}

struct MessageAPI : Keyable {
    enum Keys : String {
        case getMessage
    }
    
    func getMessage(store: MessageStore, arguments: NoArguments) -> Message {
        store.getMessage()
    }
}
```

#### Defining the service

Now we can finally define the Schema using the builder pattern.

```swift
struct MessageService : Service {
    let root: MessageAPI
    let schema: Schema<MessageAPI, MessageStore>
    
    // Notice that `Service` allows dependency injection.
    // You could pass mocked subtypes of `root` and `context` when testing, for example.
    init(root: MessageAPI) throws {
        self.root = root

        self.schema = try Schema<MessageAPI, MessageStore> { schema in
            schema.type(Message.self) { type in
                type.field(.content, at: \.content)
            }

            schema.query { query in
                query.field(.getMessage, at: MessageAPI.getMessage)
            }
        }
    }
}
```

#### Querying

To query the schema we need to instantiate the service and pass in an EventLoopGroup to feed the execute function alongside the query itself.

```swift
import NIO

let root = MessageAPI()
let context = MessageStore()
let service = try MessageService(root: root)
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
defer {
    try? group.syncShutdownGracefully()
}

let result = try service.execute(
    request: "{ getMessage { content } }",
    context: context,
    on: group
).wait()

print(result)
```

The output will be:

```json
{"data":{"getMessage":{"content":"Hello, world!"}}}
```

`Service.execute` returns a `GraphQLResult` which adopts `Encodable`. You can use it with a `JSONEncoder` to send the response back to the client using JSON.

#### Async resolvers

To use async resolvers, just add one more parameter with type `EventLoopGroup` to the resolver function and change the return type to `EventLoopFuture<YouReturnType>`. Don't forget to import NIO.

```swift
import NIO

struct API : Keyable {
    enum Keys : String {
        case getMessage
    }
    
    func getMessage(
    	store: MessageStore,
    	arguments: NoArguments,
    	group: EventLoopGroup
    ) -> EventLoopFuture<Message> {
        group.next().makeSucceededFuture(store.getMessage())
    }
}
```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/GraphQLSwift/Graphiti.svg?branch=master
[travis-url]: https://travis-ci.org/GraphQLSwift/Graphiti
[codecov-badge]: https://codecov.io/gh/GraphQLSwift/Graphiti/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/GraphQLSwift/Graphiti
[codebeat-badge]: https://codebeat.co/badges/df113480-6e62-43e0-8c9d-4571c4307e19
[codebeat-url]: https://codebeat.co/projects/github-com-graphqlswift-graphiti
