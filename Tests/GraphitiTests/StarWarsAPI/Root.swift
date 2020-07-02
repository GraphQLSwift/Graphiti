import Graphiti

extension Character {
    public var secretBackstory: String? {
        nil
    }
    
    public func getFriends(store: Store, arguments: NoArguments) -> [Character] {
        []
    }
}

extension Human {
    public func getFriends(store: Store, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
    public func getSecretBackstory(store: Store, arguments: NoArguments) throws -> String? {
        try store.getSecretBackStory()
    }
}

extension Droid {
    public func getFriends(store: Store, arguments: NoArguments) -> [Character] {
        store.getFriends(of: self)
    }
    
    public func getSecretBackstory(store: Store, arguments: NoArguments) throws -> String? {
        try store.getSecretBackStory()
    }
}

public struct Root {
    public init() {}
    
    public struct HeroArguments : Codable {
        public let episode: Episode?
    }

    public func hero(store: Store, arguments: HeroArguments) -> Character {
        store.getHero(of: arguments.episode)
    }

    public struct HumanArguments : Codable {
        public let id: String
    }
    
    public func human(store: Store, arguments: HumanArguments) -> Human? {
        store.getHuman(id: arguments.id)
    }

    public struct DroidArguments : Codable {
        public let id: String
    }

    public func droid(store: Store, arguments: DroidArguments) -> Droid? {
        store.getDroid(id: arguments.id)
    }
    
    public struct SearchArguments : Codable {
        public let query: String
    }
    
    public func search(store: Store, arguments: SearchArguments) -> [SearchResult] {
        store.search(query: arguments.query)
    }
}
