
# Usage Guide

The following sections build up a Graphiti schema and detail how to use some of the main features.

## Hello World

Here is an example of a basic `"Hello world"` GraphQL schema:

```swift
import Graphiti
import NIO

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

struct HelloResolver {
    func hello(context: NoContext, arguments: NoArguments) -> String {
        return "world"
    }
}

struct HelloAPI : API {
    typealias ContextType = NoContext
    let resolver = HelloResolver()
    let schema = try! Schema<HelloResolver, NoContext> {
        Query {
            Field("hello", at: HelloResolver.hello)
        }
    }
}
```

This schema can be queried in Swift using the `execute` function. :

```swift
let result = try await HelloAPI().execute(
    request: "{ hello }",
    context: NoContext(),
    on: eventLoopGroup
)
print(result)
```

The result of this query is a `GraphQLResult` that encodes to the following JSON:

```json
{ "hello": "world" }
```

## Swift Types

Graphiti includes support for using Swift types in the schema itself. To connect the Swift type with the GraphQL one, include a `Type` block in the API declaration, composed of `Field`s. For example, we can integrate a `Person` object into the API:

```swift
import Graphiti
import NIO

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

struct Person: Codable {
    let name: String
    let age: Int
    let height: Double
}

let characters = [
    Person(name: "Johnny Utah", age: 23, height: 1.85),
    Person(name: "Bodhi", age: 27, height: 1.8),
]

struct PersonResolver {
    func people(context: NoContext, arguments: NoArguments) -> [Person] {
        return characters
    }
}

struct PointBreakAPI : API {
    typealias ContextType = NoContext
    let resolver = PersonResolver()
    let schema = try! Schema<PersonResolver, NoContext> {
        Type(Person.self) {
            Field("name", at: \.name)
            Field("age", at: \.age)
            Field("height", at: \.height)
        }
        Query {
            Field("people", at: PersonResolver.people)
        }
    }
}

let result = try await PointBreakAPI().execute(
    request: """
    {
      people {
        name
        age
      }
    }
    """,
    context: NoContext(),
    on: eventLoopGroup
)
```

The `result` above could be decoded to a JSON of the form:

```json
{
  "people" : [
    {
      "name" : "Johnny Utah",
      "age" : 23
    },
    {
      "name" : "Bodhi",
      "age" : 27
    }
  ]
}
```

## Arguments

Arguments can be defined within an API using the `Argument` initializer in a `Field` builder. Adjusting our previous example, we can add in an argument to filter people by their age.

```swift
struct PeopleArguments: Codable {
    let olderThan: Int
}

struct PersonResolver {
    func people(context: NoContext, arguments: PeopleArguments) -> [Person] {
        return characters.filter { $0.age > arguments.olderThan }
    }
}

struct PointBreakAPI : API {
    typealias ContextType = NoContext
    let resolver = PersonResolver()
    let schema = try! Schema<PersonResolver, NoContext> {
        Type(Person.self) {
            Field("name", at: \.name)
            Field("age", at: \.age)
            Field("height", at: \.height)
        }
        Query {
            Field("people", at: PersonResolver.people) {
                Argument("olderThan", at: \.olderThan)
            }
        }
    }
}
```

A request string for this might be:

```graphql
{
  people(olderThan: 25) {
    name
  }
}
```

which would generate the response:

```json
{
  "people" : [
    {
      "name" : "Bodhi"
    }
  ]
}
```

## Mutations

Mutations are defined using a `Mutation` block in the API, and are typically used to change an underlying dataset. We can expand our example to include a mutation that creates a new person:

```swift
struct NewPersonArguments: Codable {
    let name: String
    let age: Int
    let height: Double
}

struct PersonResolver {
    func people(context: NoContext, arguments: NoArguments) -> [Person] {
        return characters
    }
    func newPerson(context: NoContext, arguments: NewPersonArguments) -> Person {
        return Person(
            name: arguments.name,
            age: arguments.age,
            height: arguments.height
        )
    }
}

struct PointBreakAPI : API {
    typealias ContextType = NoContext
    let resolver = PersonResolver()
    let schema = try! Schema<PersonResolver, NoContext> {
        Type(Person.self) {
            Field("name", at: \.name)
            Field("age", at: \.age)
            Field("height", at: \.height)
        }
        Query {
            Field("people", at: PersonResolver.people)
        }
        Mutation {
            Field("newPerson", at: PersonResolver.newPerson) {
                Argument("name", at: \.name)
                Argument("age", at: \.age)
                Argument("height", at: \.height)
            }
        }
    }
}
```

A request string for this might be:

```graphql
mutation {
  newPerson(name: "Tyler Endicott", age: 22, height: 1.63) {
    name
  }
}
```

which would generate the response:

```json
{
  "newPerson" : {
    "name" : "Tyler Endicott"
  }
}
```

## Input Objects

Sometimes we'd like to pass a complex argument. `Input`s allow us to do this and are declared by including an `Input` block in the API declaration, composed of `InputField`s. Our example can be changed to include a mutation that creates multiple new people, each passed as an input object:

```swift
struct InputPerson: Codable {
    let name: String
    let age: Int
    let height: Double
}

struct NewPeopleArguments: Codable {
    let individuals: [InputPerson]
}

struct PersonResolver {
    func people(context: NoContext, arguments: NoArguments) -> [Person] {
        return characters
    }
    func newPeople(context: NoContext, arguments: NewPeopleArguments) -> [Person] {
        return arguments.individuals.map { person in
            Person(
                name: person.name,
                age: person.age,
                height: person.height
            )
        }
    }
}

struct PointBreakAPI : API {
    typealias ContextType = NoContext
    let resolver = PersonResolver()
    let schema = try! Schema<PersonResolver, NoContext> {
        Type(Person.self) {
            Field("name", at: \.name)
            Field("age", at: \.age)
            Field("height", at: \.height)
        }
        Input(InputPerson.self) {
            InputField("name", at: \.name)
            InputField("age", at: \.age)
            InputField("height", at: \.height)
        }
        Query {
            Field("people", at: PersonResolver.people)
        }
        Mutation {
            Field("newPeople", at: PersonResolver.newPeople) {
                Argument("individuals", at: \.individuals)
            }
        }
    }
}
```

A request might look like:

```graphql
mutation {
  newPeople(individuals: [
    {name: "Tyler Endicott", age: 22, height: 1.63},
    {name: "Angelo Pappas", age: 45, height: 1.91},
  ]) {
    name
  }
}
```

which would generate the response:

```json
{
  "newPeople" : [
    {
      "name" : "Tyler Endicott"
    },
    {
      "name" : "Angelo Pappas"
    }
  ]
}
```

## Subscriptions

Subscriptions are reactive queries that return a result whenever an event occurs. This functionality is built on Swift Concurrency using `AsyncThrowingStream`. To create a subscription, include a `Subscription` block in the API declaration composed of `SubscriptionFields`. We can change our example API to include a subscription alert:

```swift
import Foundation
import GraphQL

let timer: Timer!

struct PersonResolver {
    func people(context: NoContext, arguments: NoArguments) -> [Person] {
        return characters
    }
    func fiftyYearStormAlert(context: NoContext, arguments: NoArguments) -> ConcurrentEventStream<String> {
        let asyncStream = AsyncThrowingStream<String, Error> { continuation in
            timer = Timer.scheduledTimer(
                withTimeInterval: 60 * 60 * 24 * 365 * 50,
                repeats: true
            ) { _ in
                continuation.yield("A 50-year storm is occurring!")
            }
        }
        return ConcurrentEventStream<String>.init(asyncStream)
    }
}

struct PointBreakAPI : API {
    typealias ContextType = NoContext
    let resolver = PersonResolver()
    let schema = try! Schema<PersonResolver, NoContext> {
        Type(Person.self) {
            Field("name", at: \.name)
            Field("age", at: \.age)
            Field("height", at: \.height)
        }
        Query {
            Field("people", at: PersonResolver.people)
        }
        Subscription {
            SubscriptionField(
                "fiftyYearStormAlert",
                at: FiftyYearStorm.message,
                atSub: PersonResolver.fiftyYearStormAlert
            )
        }
    }
}
```

This schema can be subscribed to in Swift using the `subscribe` function. The example below illustrates this and prints the result on each occurance (To see results, you should probably change the timer to execute on a period faster than 50 years):

```swift
let api = PointBreakAPI()
let stream = try await api.subscribe(
    request: "subscription { fiftyYearStormAlert }",
    context: NoContext(),
    on: eventLoopGroup
).stream!
let resultStream = stream.map { result in
    try print(result.wait())
}
```

Each time an event fires, the following message will be generated:

```json
{
  "fiftyYearStormAlert": "A 50-year storm is occurring!"
}
```
