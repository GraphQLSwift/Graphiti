import Graphiti

@available(macOS 12.0.0, *)
extension Character {
    public var secretBackstory: String? {
        nil
    }
}

@available(macOS 12.0.0, *)
extension Human {
    public var getFriends: (StarWarsContext, Void) async throws -> [Character] {
        return { context, _ in
            await context.getFriends(of: self)
        }
    }
    
    public var getSecretBackstory: (StarWarsContext, Void) async throws -> String? {
        return { context, _ in
            try await context.getSecretBackStory()
        }
    }
}

@available(macOS 12.0.0, *)
extension Droid {
    public var getFriends: (StarWarsContext, Void) async throws -> [Character] {
        return { context, _ in
            await context.getFriends(of: self)
        }
    }
    
    public var getSecretBackstory: (StarWarsContext, Void) async throws -> String? {
        return { context, _ in
            try await context.getSecretBackStory()
        }
    }
}

@available(macOS 12.0.0, *)
public struct StarWarsResolver {
    public struct HeroArguments: Codable {
        public let episode: Episode?
    }

    public var hero: (StarWarsContext, HeroArguments) async throws -> Character

    public struct HumanArguments: Codable {
        public let id: String
    }
    
    public var human: (StarWarsContext, HumanArguments) async throws -> Human?

    public struct DroidArguments: Codable {
        public let id: String
    }

    public var droid: (StarWarsContext, DroidArguments) async throws -> Droid?
    
    public struct SearchArguments: Codable {
        public let query: String
    }
    
    public var search: (StarWarsContext, SearchArguments) async throws -> [SearchResult]
}

@available(macOS 12.0.0, *)
public extension StarWarsResolver {
    static let live = StarWarsResolver(
        hero: { context, arguments in
            await context.getHero(of: arguments.episode)
        },
        human: { context, arguments in
            await context.getHuman(id: arguments.id)
        },
        droid: { context, arguments in
            await context.getDroid(id: arguments.id)
        },
        search: { context, arguments in
            await context.search(query: arguments.query)
        }
    )
}
