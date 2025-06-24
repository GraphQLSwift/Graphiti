
# Usage Guide

The following sections build up a Graphiti schema and detail how to use some of the main features.

## Hello World

Here is an example of a basic `"Hello world"` GraphQL schema:

```swift
import Graphiti

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
    context: NoContext()
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
    context: NoContext()
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
    context: NoContext()
)
for try await event in stream {
    try print(event)
}
```

Each time an event fires, the following message will be generated:

```json
{
  "fiftyYearStormAlert": "A 50-year storm is occurring!"
}
```

## Cursor Connections

This package supports pagination using the [Relay-based GraphQL Cursor Connections Specification](https://relay.dev/graphql/connections.htm). To use this pagination style you must:

1. Ensure any `node` types implement the `Identifiable` protocol (they must have a unique `id` field)
2. Change the relevant resolver types to use `PaginationArguments` and return a `Connection`
3. Add the `PaginationArguments` arguments to the schema declaration

Here's an example using the schema above:

```swift
struct Person: Codable, Identifiable {
    let id: Int
    let name: String
}

let characters = [
    Person(id: 1, name: "Johnny Utah"),
    Person(id: 2, name: "Bodhi"),
]

struct PersonResolver {
    func people(context: NoContext, arguments: PaginationArguments) throws -> Connection<Person> {
        return try characters.connection(from: arguments)
    }
}

struct PointBreakAPI : API {
    typealias ContextType = NoContext
    let resolver = PersonResolver()
    let schema = try! Schema<PersonResolver, NoContext> {
        Type(Person.self) {
            Field("id", at: \.id)
            Field("name", at: \.name)
        }
        ConnectionType(Person.self)
        Query {
            Field("people", at: PersonResolver.people) {
                Argument("first", at: \.first)
                Argument("last", at: \.last)
                Argument("after", at: \.after)
                Argument("before", at: \.before)
            }
        }
    }
}
```

A request string for this might be:

```graphql
{
    people {
        edges {
            cursor
            node {
                id
                name
            }
        }
        pageInfo {
            hasPreviousPage
            hasNextPage
            startCursor
            endCursor
        }
    }
}
```

The result of this query is a `GraphQLResult` that encodes to the following JSON:

```json
{
    "people": {
        "edges": [
            {
                "cursor": "MQ==",
                "node": {
                    "id": 1,
                    "name": "Johnny Utah"
                }
            },
            {
                "cursor": "Mg==",
                "node": {
                    "id": 2,
                    "name": "Bodhi"
                }
            },
        ],
        "pageInfo": {
            "hasPreviousPage": false,
            "hasNextPage": false,
            "startCursor": "MQ==",
            "endCursor": "Mg=="
        }
    }
}
```

## Federation

Federation allows you split your GraphQL API into smaller services and link them back together so clients see a single larger API. More information can be found [here](https://www.apollographql.com/docs/federation). To enable federation you must:

1. Define `Keys` on the entity types, which specify the primary key fields and the resolver function used to load an entity from that key.
2. Provide the schema SDL to the schema itself.

Here's an example for the following schema:

```graphql
extend schema @link(url: "https://specs.apollo.dev/federation/v2.0", import: [ "@extends", "@external", "@key", "@inaccessible", "@override", "@provides", "@requires", "@shareable", "@tag"])

type Product {
    id: ID!
    sku: String
    createdBy: User
}

extend type Query {
  product(id: ID!): Product
}

extend type User @key(fields: "email") {
  email: ID! @external
  name: String @override(from: "users")
  totalProductsCreated: Int @external
  yearsOfEmployment: Int! @external
}
```

```swift
import Foundation
import Graphiti

struct Product: Codable {
    let id: String
    let sku: String
    let createdBy: User
}

struct User: Codable {
    let email: String
    let name: String?
    let totalProductsCreated: Int?
    let yearsOfEmployment: Int
}

struct ProductContext {
    func getUser(email: String) -> User { ... }
}

struct ProductResolver {
    struct UserArguments: Codable {
        let email: String
    }

    func user(context: ProductContext, arguments: UserArguments) -> User? {
        context.getUser(email: arguments.email)
    }
}

final class ProductSchema: PartialSchema<ProductResolver, ProductContext> {
    @TypeDefinitions
    override var types: Types {
        Type(Product.self) {
            Field("id", at: \.id)
            Field("sku", at: \.sku)
            Field("createdBy", at: \.createdBy)
        }

        Type(
            User.self,
            keys: {
                Key(at: ProductResolver.user) {
                    Argument("email", at: \.email)
                }
            }
        ) {
            Field("email", at: \.email)
            Field("name", at: \.name)
            Field("totalProductsCreated", at: \.totalProductsCreated)
            Field("yearsOfEmployment", at: \.yearsOfEmployment)
        }
    }
}

struct ProductAPI: API {
    let resolver: ProductResolver
    let schema: Schema<ProductResolver, ProductContext>
}

let schema = try SchemaBuilder(ProductResolver.self, ProductContext.self)
    .use(partials: [ProductSchema()])
    .setFederatedSDL(to: getSDL())
    .build()

let api = ProductAPI(resolver: ProductResolver(), schema: schema)

try await api.execute(
    request: """
    query {
      _entities(representations: {__typename: "User", email: "abc@def.com"}) {
        ... on User {
          email
          name
        }
      }
    }
    """,
    context: ProductContext()
)
```
