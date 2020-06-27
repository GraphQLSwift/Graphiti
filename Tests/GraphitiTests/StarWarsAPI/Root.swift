import Graphiti

extension Episode : Enumerable {}

extension Character {
    public var secretBackstory: String? {
        nil
    }
    
    public func getFriends(store: Store, arguments: NoArguments) -> [Character] {
        []
    }
}

public final class AnyCharacter : Character, InterfaceReference {
    public typealias InterfaceType = Character
    
    public enum Keys : String {
        case id
        case name
        case friends
        case appearsIn
        case secretBackstory
    }
    
    private let character: Character
    
    public init(_ character: Character) {
        self.character = character
    }
    
    public var id: String {
        self.character.id
    }
    
    public var name: String {
        self.character.name
    }
    
    public var friends: [String] {
        self.character.friends
    }
    
    public var appearsIn: [Episode] {
        self.character.appearsIn
    }
}

extension Planet : Keyable {
    public enum Keys : String {
        case id
        case name
        case diameter
        case rotationPeriod
        case orbitalPeriod
        case residents
    }
}

extension Human : Keyable {
    public enum Keys : String {
        case id
        case name
        case appearsIn
        case homePlanet
        case friends
        case secretBackstory
    }
    
    public func getFriends(store: Store, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
    public func getSecretBackstory(store: Store, arguments: NoArguments) throws -> String? {
        try store.getSecretBackStory()
    }
}

extension Droid : Keyable {
    public enum Keys : String {
        case id
        case name
        case appearsIn
        case primaryFunction
        case friends
        case secretBackstory
    }
    
    public func getFriends(store: Store, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
    public func getSecretBackstory(store: Store, arguments: NoArguments) throws -> String? {
        try store.getSecretBackStory()
    }
}

public struct Root : Keyable {
    public enum Keys : String {
        case id
        case episode
        case hero
        case human
        case droid
        case search
        case query
    }
    
    public init() {}
    
    public struct HeroArguments : Codable {
        public let episode: Episode?
    }

    public func getHero(store: Store, arguments: HeroArguments) -> Character {
        store.getHero(of: arguments.episode)
    }

    public struct HumanArguments : Codable {
        public let id: String
    }
    
    public func getHuman(store: Store, arguments: HumanArguments) -> Human? {
        store.getHuman(id: arguments.id)
    }

    public struct DroidArguments : Codable {
        public let id: String
    }

    public func getDroid(store: Store, arguments: DroidArguments) -> Droid? {
        store.getDroid(id: arguments.id)
    }
    
    public struct SearchArguments : Codable {
        public let query: String
    }
    
    public func search(store: Store, arguments: SearchArguments) -> [SearchResult] {
        store.search(query: arguments.query)
    }
}
