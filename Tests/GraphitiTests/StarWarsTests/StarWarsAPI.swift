import Graphiti

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
    
    func getFriends(store: StarWarsStore, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
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
    
    struct HeroArguments : Codable {
        let episode: Episode?
    }

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
