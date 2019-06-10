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
        .Package(url: "https://github.com/GraphQLSwift/Graphiti.git", .upToNextMinor(from: "0.10.0")),
    ]
)
```

Graphiti provides two important capabilities: building a type schema, and
serving queries against that type schema.

#### Defining entities

First, we declare our regular Swift entities. Here we are using GraphQL's classic  Star Wars API example.

```swift
enum Episode : String, Codable {
    case newHope = "NEWHOPE"
    case empire = "EMPIRE"
    case jedi = "JEDI"
}

protocol Character : Codable {
    var id: String { get }
    var name: String { get }
    var friends: [String] { get }
    var appearsIn: [Episode] { get }
}

struct Planet : Codable {
    let id: String
    let name: String
    let diameter: Int
    let rotationPeriod: Int
    let orbitalPeriod: Int
    var residents: [Human]
}

struct Human : Character {
    let id: String
    let name: String
    let friends: [String]
    let appearsIn: [Episode]
    let homePlanet: Planet
}

struct Droid : Character {
    let id: String
    let name: String
    let friends: [String]
    let appearsIn: [Episode]
    let primaryFunction: String
}

protocol SearchResult {}
extension Planet: SearchResult {}
extension Human: SearchResult {}
extension Droid: SearchResult {}
```

One of the main design decisions behing Graphiti is **not** to polute your entities declarations. This way you can bring your entities to any other solution with ease.

#### Defining the context

Second step is to create your application's **context**. The context will be passed to all of your field resolver functions. This allows you to apply dependency injection to your API. You will usually use the Context as the state holder of your API. Therefore, this will often be a `final class`. We're calling it a store here, because that's the only thing that it does, but you should name it in a way that is appropriate to what your context does.

```swift
/**
 * This defines a basic set of data for our Star Wars Schema.
 *
 * This data is hard coded for the sake of the demo, but you could imagine
 * fetching this data from a backend service rather than from hardcoded
 * values in a more complex demo.
 */
final class StarWarsStore {
    lazy var tatooine = Planet(
        id:"10001",
        name: "Tatooine",
        diameter: 10465,
        rotationPeriod: 23,
        orbitalPeriod: 304,
        residents: []
    )
    
    lazy var alderaan = Planet(
        id: "10002",
        name: "Alderaan",
        diameter: 12500,
        rotationPeriod: 24,
        orbitalPeriod: 364,
        residents: []
    )
    
    lazy var planetData: [String: Planet] = [
        "10001": tatooine,
        "10002": alderaan,
    ]
    
    lazy var luke = Human(
        id: "1000",
        name: "Luke Skywalker",
        friends: ["1002", "1003", "2000", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: tatooine
    )
    
    lazy var vader = Human(
        id: "1001",
        name: "Darth Vader",
        friends: [ "1004" ],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: tatooine
    )
    
    lazy var han = Human(
        id: "1002",
        name: "Han Solo",
        friends: ["1000", "1003", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: alderaan
    )
    
    lazy var leia = Human(
        id: "1003",
        name: "Leia Organa",
        friends: ["1000", "1002", "2000", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: alderaan
    )
    
    lazy var tarkin = Human(
        id: "1004",
        name: "Wilhuff Tarkin",
        friends: ["1001"],
        appearsIn: [.newHope],
        homePlanet: alderaan
    )
    
    lazy var humanData: [String: Human] = [
        "1000": luke,
        "1001": vader,
        "1002": han,
        "1003": leia,
        "1004": tarkin,
    ]
    
    lazy var c3po = Droid(
        id: "2000",
        name: "C-3PO",
        friends: ["1000", "1002", "1003", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        primaryFunction: "Protocol"
    )
    
    lazy var r2d2 = Droid(
        id: "2001",
        name: "R2-D2",
        friends: [ "1000", "1002", "1003" ],
        appearsIn: [.newHope, .empire, .jedi],
        primaryFunction: "Astromech"
    )
    
    lazy var droidData: [String: Droid] = [
        "2000": c3po,
        "2001": r2d2,
    ]
    
    /**
     * Helper function to get a character by ID.
     */
    func getCharacter(id: String) -> Character? {
        humanData[id] ?? droidData[id]
    }
    
    /**
     * Allows us to query for a character"s friends.
     */
    func getFriends(of character: Character) -> [Character] {
        character.friends.compactMap { id in
            getCharacter(id: id)
        }
    }
    
    /**
     * Allows us to fetch the undisputed hero of the Star Wars trilogy, R2-D2.
     */
    func getHero(of episode: Episode?) -> Character {
        if episode == .empire {
            // Luke is the hero of Episode V.
            return luke
        }
        // R2-D2 is the hero otherwise.
        return r2d2
    }
    
    /**
     * Allows us to query for the human with the given id.
     */
    func getHuman(id: String) -> Human? {
        humanData[id]
    }
    
    /**
     * Allows us to query for the droid with the given id.
     */
    func getDroid(id: String) -> Droid? {
        droidData[id]
    }
    
    /**
     * Allows us to get the secret backstory, or not.
     */
    func getSecretBackStory() throws -> String? {
        struct Secret : Error, CustomStringConvertible {
            let description: String
        }
        
        throw Secret(description: "secretBackstory is secret.")
    }
    
    /**
     * Allows us to query for a Planet.
     */
    func getPlanets(query: String) -> [Planet] {
        planetData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }
    
    /**
     * Allows us to query for a Human.
     */
    func getHumans(query: String) -> [Human] {
        humanData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }
    
    /**
     * Allows us to query for a Droid.
     */
    func getDroids(query: String) -> [Droid] {
        droidData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }

    /**
     * Allows us to query for either a Human, Droid, or Planet.
     */
    func search(query: String) -> [SearchResult] {
        return getPlanets(query: query) + getHumans(query: query) + getDroids(query: query)
    }
}
```

Notice again that this step doesn't require Graphiti. It's purely business logic.

#### Defining the API implementation

Now that we have our entities and context we can create the API itself.

```swift
import Graphiti

// secretBackstory is a property that doesn't exist in our original entity,
// but we'd like to expose it to Graphiti.
extension Character {
    var secretBackstory: String? {
        return nil
    }
}

// In aligment with our guidelines we have to define the keys for protocols
// in a global enum, because we can't adopt FieldKeyProvider in protocol
// extensions. The role of FieldKeyProvider will become clearer in the
// next extension.
enum CharacterFieldKeys : String {
    case id
    case name
    case friends
    case appearsIn
    case secretBackstory
}

// FieldKeyProvider is a protocol that allows us to define the keys which
// will be used to map properties and functions to GraphQL fields.
extension Planet : FieldKeyProvider {
    typealias FieldKey = FieldKeys
    
    enum FieldKeys : String {
        case id
        case name
        case diameter
        case rotationPeriod
        case orbitalPeriod
        case residents
    }
}

extension Human : FieldKeyProvider {
    typealias FieldKey = FieldKeys
    
    enum FieldKeys : String {
        case id
        case name
        case appearsIn
        case homePlanet
        case friends
        case secretBackstory
    }
    
    // This is the basic layout of a resolve function.
    // The first parameter is the context and the second parameter are
    // the arguments. In this case we have no arguments so we use the
    // provided type `NoArguments`. In a later example you will see how
    // to use parameters.
    func getFriends(store: StarWarsStore, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
    // Resolve functions can throw.
    func getSecretBackstory(store: StarWarsStore, arguments: NoArguments) throws -> String? {
        try store.getSecretBackStory()
    }
}

extension Droid : FieldKeyProvider {
    typealias FieldKey = FieldKeys
    
    enum FieldKeys : String {
        case id
        case name
        case appearsIn
        case primaryFunction
        case friends
        case secretBackstory
    }
    
    func getFriends(store: StarWarsStore, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
    func getSecretBackstory(store: StarWarsStore, arguments: NoArguments) throws -> String? {
        try store.getSecretBackStory()
    }
}

struct StarWarsAPI : FieldKeyProvider {
    typealias FieldKey = FieldKeys
    
    enum FieldKeys : String {
        case id
        case episode
        case hero
        case human
        case droid
        case search
        case query
    }
    
    // Here we are defining the arguments for the getHero function.
    // Arguments need to adopt the Codable protocol.
    struct HeroArguments : Codable {
        let episode: Episode?
    }

    // Here we're simplin defining `HeroArguments` as the arguments for the
    // getHero function.
    func getHero(store: StarWarsStore, arguments: HeroArguments) -> Character {
        store.getHero(of: arguments.episode)
    }

    struct HumanArguments : Codable {
        let id: String
    }
    
    func getHuman(store: StarWarsStore, arguments: HumanArguments) -> Human? {
        store.getHuman(id: arguments.id)
    }

    struct DroidArguments : Codable {
        let id: String
    }

    func getDroid(store: StarWarsStore, arguments: DroidArguments) -> Droid? {
        store.getDroid(id: arguments.id)
    }
    
    struct SearchArguments : Codable {
        let query: String
    }
    
    func search(store: StarWarsStore, arguments: SearchArguments) -> [SearchResult] {
        store.search(query: arguments.query)
    }
}
```

#### Defining the schema

Now we can finally define the Schema using Swift 5.1 function builders.

```swift
import Graphiti

// Here we're defining our root type StarWarsAPI and the context
// StarWarsStore as the generic parameters of Schema.
let starWarsSchema = Schema<StarWarsAPI, StarWarsStore> {
    Enum(Episode.self) {
        Value(.newHope)
        .description("Released in 1977.")

        Value(.empire)
        .description("Released in 1980.")

        Value(.jedi)
        .description("Released in 1983.")
    }
    .description("One of the films in the Star Wars Trilogy.")

    Interface(Character.self, fieldKeys: CharacterFieldKeys.self) {
        Field(.id, at: \.id)
        .description("The id of the character.")

        Field(.name, at: \.name)
        .description("The name of the character.")

        Field(.friends, at: \.friends, overridingType: [TypeReference<Character>].self)
        .description("The friends of the character, or an empty list if they have none.")

        Field(.appearsIn, at: \.appearsIn)
        .description("Which movies they appear in.")

        Field(.secretBackstory, at: \.secretBackstory)
        .description("All secrets about their past.")
    }
    .description("A character in the Star Wars Trilogy.")

    Type(Planet.self) {
        Field(.id, at: \.id)
        Field(.name, at: \.name)
        Field(.diameter, at: \.diameter)
        Field(.rotationPeriod, at: \.rotationPeriod)
        Field(.orbitalPeriod, at: \.orbitalPeriod)
        Field(.residents, at: \.residents, overridingType: [TypeReference<Human>].self)
    }
    .description("A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY.")

    Type(Human.self, interfaces: Character.self) {
        Field(.id, at: \.id)
        Field(.name, at: \.name)
        Field(.appearsIn, at: \.appearsIn)
        Field(.homePlanet, at: \.homePlanet)

        Field(.friends, at: Human.getFriends)
        .description("The friends of the human, or an empty list if they have none.")

        Field(.secretBackstory, at: Human.getSecretBackstory)
        .description("Where are they from and how they came to be who they are.")
    }
    .description("A humanoid creature in the Star Wars universe.")

    Type(Droid.self, interfaces: Character.self) {
        Field(.id, at: \.id)
        Field(.name, at: \.name)
        Field(.appearsIn, at: \.appearsIn)
        Field(.primaryFunction, at: \.primaryFunction)

        Field(.friends, at: Droid.getFriends)
        .description("The friends of the droid, or an empty list if they have none.")

        Field(.secretBackstory, at: Droid.getSecretBackstory)
        .description("Where are they from and how they came to be who they are.")
    }
    .description("A mechanical creature in the Star Wars universe.")

    Union(SearchResult.self, members: Planet.self, Human.self, Droid.self)

    Query {
        Field(.hero, at: StarWarsAPI.getHero)
        .description("Returns a hero based on the given episode.")
        .argument(.episode, at: \.episode, description: "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.")

        Field(.human, at: StarWarsAPI.getHuman)
        .argument(.id, at: \.id, description: "Id of the human.")

        Field(.droid, at: StarWarsAPI.getDroid)
        .argument(.id, at: \.id, description: "Id of the droid.")

        Field(.search, at: StarWarsAPI.search)
        .argument(.query, at: \.query, defaultValue: "R2-D2")
    }

    Types(Human.self, Droid.self)
}
```

#### Querying

To query the schema we need to create an EventLoopGroup to feed the execute function alongside the query itself.

```swift
import NIO

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
defer {
    try? eventLoopGroup.syncShutdownGracefully()
}
    
let query = """
query HeroNameQuery {
    hero {
        name
    }
}
"""
 
let result = try starWarsSchema.execute(
    request: query,
    root: self.starWarsAPI,
    context: self.starWarsStore,
    eventLoopGroup: eventLoopGroup
).wait()

print(result)
```

The output will be:

```json
{"data":{"hero":{"name":"R2-D2"}}}
```

`Schema.execute` returns a `GraphQLResult` which adopts `Encodable`. You can use it with a `JSONEncoder` to send the response back to the client using JSON.

#### Async resolvers

To use async resolvers, just add one more parameter with type `EventLoopGroup` to the resolver function and chage the return type to `EventLoopFuture<YouReturnType>`. Don't forget to import NIO.

```swift
import NIO

struct API : FieldKeyProvider {
    typealias FieldKey = FieldKeys
    
    enum FieldKeys : String {
        case hello
    }
    
    func hello(
    	context: NoContext,
    	arguments: NoArguments,
    	eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<String> {
        eventLoopGroup.next().newSucceededFuture(result: "world")
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
