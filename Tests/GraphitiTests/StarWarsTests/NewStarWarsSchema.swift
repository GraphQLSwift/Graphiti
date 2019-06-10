import GraphQL
import Graphiti
import NIO

extension Episode : InputType, OutputType {}

extension Character {
    var secretBackstory: String? {
        return nil
    }
}

enum CharacterFieldKeys : String {
    case id
    case name
    case friends
    case appearsIn
    case secretBackstory
}

extension Planet : OutputType, FieldKeyProvider {
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

extension Human : OutputType, FieldKeyProvider {
    typealias FieldKey = FieldKeys
    
    enum FieldKeys : String {
        case id
        case name
        case appearsIn
        case homePlanet
        case friends
        case secretBackstory
    }
    
    func getFriends(store: StarWarsStore, arguments: NoArguments) -> [Character] {
        return store.getFriends(character: self)
    }
    
    func getSecretBackstory(store: StarWarsStore, arguments: NoArguments) throws -> String? {
        return try store.getSecretBackStory()
    }
}

extension Droid : OutputType, FieldKeyProvider {
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
        return store.getFriends(character: self)
    }
    
    func getSecretBackstory(store: StarWarsStore, arguments: NoArguments) throws -> String? {
        return try store.getSecretBackStory()
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
    
    struct HeroArguments : ArgumentType {
        let episode: Episode?
    }

    func getHero(store: StarWarsStore, arguments: HeroArguments) -> Character {
        return store.getHero(episode: arguments.episode)
    }

    struct HumanArguments : ArgumentType {
        let id: String
    }
    
    func getHuman(store: StarWarsStore, arguments: HumanArguments) -> Human? {
        return store.getHuman(id: arguments.id)
    }

    struct DroidArguments : ArgumentType {
        let id: String
    }

    func getDroid(store: StarWarsStore, arguments: DroidArguments) -> Droid? {
        return store.getDroid(id: arguments.id)
    }
    
    struct SearchArguments : ArgumentType {
        let query: String
    }
    
    func search(store: StarWarsStore, arguments: SearchArguments) -> [SearchResult] {
        return store.search(for: arguments.query)
    }
}

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
