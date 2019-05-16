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
        .Package(url: "https://github.com/GraphQLSwift/Graphiti.git", majorVersion: 0, minor: 8),
    ]
)
```

Graphiti provides two important capabilities: building a type schema, and
serving queries against that type schema.

First, build a Graphiti type schema which maps to your code base.

```swift
let schema = try Schema<Void> { schema in
    schema.query { query in
        try query.field(name: "hello", type: String.self) { (_, _, _, eventLoop, _) in
            return eventLoop.next().newSucceededFuture(result: "world")
        }
    }
}
```

This defines a simple schema with one type and one field, that resolves
to a fixed value. More complex examples are included in the [Tests](Tests/GraphitiTests/) directory.

Then, serve the result of a query against that type schema.

```swift
let query = "{ hello }"
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let result = try schema.execute(request: query, eventLoopGroup: eventLoopGroup).wait()
try eventLoopGroup.syncShutdownGracefully()
print(result)
```

Output:

```json
{
    "data": {
        "hello": "world"
    }
}
```

This runs a query fetching the one field defined. The `execute` function will
first ensure the query is syntactically and semantically valid before executing
it, reporting errors otherwise.

```swift
let query = "{ boyhowdy }"
let result = try schema.execute(request: query)
print(result)
```

Output:

```json
{
    "errors": [
        {
            "locations": [
                {
                    "line": 1,
                    "column": 3
                }
            ], 
            "message": "Cannot query field \"boyhowdy\" on type \"Query\"."
        }
    ]
}
```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-5-orange.svg?style=flat
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
