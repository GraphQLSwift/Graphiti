import Graphiti

public struct StarWarsAPI: API {
    public let resolver = StarWarsResolver()
    
    public let schema = try! Schema<StarWarsResolver, StarWarsContext> {
        Enum(Episode.self) {
            Value(.newHope)
                .description("Released in 1977.")

            Value(.empire)
                .description("Released in 1980.")

            Value(.jedi)
                .description("Released in 1983.")
        }
        .description("One of the films in the Star Wars Trilogy.")

        Interface(Character.self) {
            Field("id", at: \.id)
                .description("The id of the character.")

            Field("name", at: \.name)
                .description("The name of the character.")

            Field("friends", at: \.friends, as: [TypeReference<Character>].self)
                .description("The friends of the character, or an empty list if they have none.")

            Field("appearsIn", at: \.appearsIn)
                .description("Which movies they appear in.")

            Field("secretBackstory", at: \.secretBackstory)
                .description("All secrets about their past.")
        }
        .description("A character in the Star Wars Trilogy.")

        Type(Planet.self) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("diameter", at: \.diameter)
            Field("rotationPeriod", at: \.rotationPeriod)
            Field("orbitalPeriod", at: \.orbitalPeriod)
            Field("residents", at: \.residents, as: [TypeReference<Human>].self)
        }
        .description("A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY.")

        Type(Human.self, interfaces: [Character.self]) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("appearsIn", at: \.appearsIn)
            Field("homePlanet", at: \.homePlanet)

            Field("friends", at: Human.getFriends, as: [Character].self)
                .description("The friends of the human, or an empty list if they have none.")

            Field("secretBackstory", at: Human.getSecretBackstory)
                .description("Where are they from and how they came to be who they are.")
        }
        .description("A humanoid creature in the Star Wars universe.")

        Type(Droid.self, interfaces: [Character.self]) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("appearsIn", at: \.appearsIn)
            Field("primaryFunction", at: \.primaryFunction)

            Field("friends", at: Droid.getFriends, as: [Character].self)
                .description("The friends of the droid, or an empty list if they have none.")

            Field("secretBackstory", at: Droid.getSecretBackstory)
                .description("Where are they from and how they came to be who they are.")
        }
        .description("A mechanical creature in the Star Wars universe.")

        Union(SearchResult.self, members: Planet.self, Human.self, Droid.self)

        Query {
            Field("hero", at: StarWarsResolver.hero, as: Character.self) {
                Argument("episode", at: \.episode)
                    .description("If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.")
            }
            .description("Returns a hero based on the given episode.")


            Field("human", at: StarWarsResolver.human) {
                Argument("id", at: \.id)
                    .description("Id of the human.")
            }

            Field("droid", at: StarWarsResolver.droid) {
                Argument("id", at: \.id)
                    .description("Id of the droid.")
            }

            Field("search", at: StarWarsResolver.search, as: [SearchResult].self) {
                Argument("query", at: \.query)
                    .defaultValue("R2-D2")
            }
        }

        Types(Human.self, Droid.self)
    }
}
