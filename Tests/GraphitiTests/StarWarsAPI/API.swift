import Graphiti

public struct StarWarsAPI : API {
    public let root = Root()
    public let context = Store()
    
    public init() {}
    
    public let schema = try! Schema<Root, Store> { schema in
        schema.enum(Episode.self) { cases in
            cases.value(.newHope)
                .description("Released in 1977.")
            
            cases.value(.empire)
                .description("Released in 1980.")
            
            cases.value(.jedi)
                .description("Released in 1983.")
        }
        .description("One of the films in the Star Wars Trilogy.")

        schema.interface(AnyCharacter.self) { interface in
            interface.field(.id, at: \.id)
                .description("The id of the character.")

            interface.field(.name, at: \.name)
                .description("The name of the character.")

            interface.field(.friends, at: \.friends, overridingType: [TypeReference<Character>].self)
                .description("The friends of the character, or an empty list if they have none.")

            interface.field(.appearsIn, at: \.appearsIn)
                .description("Which movies they appear in.")

            interface.field(.secretBackstory, at: \.secretBackstory)
                .description("All secrets about their past.")
        }
        .description("A character in the Star Wars Trilogy.")

        schema.type(Planet.self) { type in
            type.field(.id, at: \.id)
            type.field(.name, at: \.name)
            type.field(.diameter, at: \.diameter)
            type.field(.rotationPeriod, at: \.rotationPeriod)
            type.field(.orbitalPeriod, at: \.orbitalPeriod)
            type.field(.residents, at: \.residents, overridingType: [TypeReference<Human>].self)
        }
        .description("A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY.")

        schema.type(Human.self, interfaces: Character.self) { type in
            type.field(.id, at: \.id)
            type.field(.name, at: \.name)
            type.field(.appearsIn, at: \.appearsIn)
            type.field(.homePlanet, at: \.homePlanet)

            type.field(.friends, at: Human.getFriends)
                .description("The friends of the human, or an empty list if they have none.")

            type.field(.secretBackstory, at: Human.getSecretBackstory)
                .description("Where are they from and how they came to be who they are.")
        }
        .description("A humanoid creature in the Star Wars universe.")

        schema.type(Droid.self, interfaces: Character.self) { type in
            type.field(.id, at: \.id)
            type.field(.name, at: \.name)
            type.field(.appearsIn, at: \.appearsIn)
            type.field(.primaryFunction, at: \.primaryFunction)

            type.field(.friends, at: Droid.getFriends)
                .description("The friends of the droid, or an empty list if they have none.")

            type.field(.secretBackstory, at: Droid.getSecretBackstory)
                .description("Where are they from and how they came to be who they are.")
        }
        .description("A mechanical creature in the Star Wars universe.")

        schema.union(SearchResult.self, members: Planet.self, Human.self, Droid.self)

        schema.query { query in
            query.field(.hero, at: Root.getHero)
                .description("Returns a hero based on the given episode.")
                .argument(.episode, at: \.episode, description: "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.")

            query.field(.human, at: Root.getHuman)
                .argument(.id, at: \.id, description: "Id of the human.")

            query.field(.droid, at: Root.getDroid)
                .argument(.id, at: \.id, description: "Id of the droid.")

            query.field(.search, at: Root.search)
                .argument(.query, at: \.query, defaultValue: "R2-D2")
        }

        schema.types(Human.self, Droid.self)
    }
}
