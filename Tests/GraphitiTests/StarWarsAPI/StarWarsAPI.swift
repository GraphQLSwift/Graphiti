import Graphiti

@available(macOS 12, *)
public struct StarWarsAPI {
    public let schema = Schema<StarWarsResolver, StarWarsContext> {
        "One of the films in the Star Wars Trilogy."
        Enum(Episode.self) {
            "Released in 1977."
            Value(.newHope)

            "Released in 1980."
            Value(.empire)

            "Released in 1983."
            Value(.jedi)
        }

        "A character in the Star Wars Trilogy."
        Interface(Character.self) {
            "The id of the character."
            Field("id", of: String.self, at: \.id)

            "The name of the character."
            Field("name", of: String.self, at: \.name)

            "The friends of the character, or an empty list if they have none."
            Field("friends", at: \.friends, as: [TypeReference<Character>].self)

            "Which movies they appear in."
            Field("appearsIn", of: [Episode].self, at: \.appearsIn)

            "All secrets about their past."
            Field("secretBackstory", of: String?.self, at: \.secretBackstory)
        }

        "A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY."
        Type(Planet.self) {
            Field("id", at: \.id)
            Field("name", at: \.name)
            Field("diameter", at: \.diameter)
            Field("rotationPeriod", at: \.rotationPeriod)
            Field("orbitalPeriod", at: \.orbitalPeriod)
            Field("residents", at: \.residents, as: [TypeReference<Human>].self)
        }

        "A humanoid creature in the Star Wars universe."
        Type(Human.self, implements: Character.self) {
            Field("id", of: String.self, at: \.id)
            Field("name", of: String.self, at: \.name)
            Field("appearsIn", of: [Episode].self, at: \.appearsIn)
            Field("homePlanet", of: Planet.self, at: \.homePlanet)

            "The friends of the human, or an empty list if they have none."
            Field("friends", at: \.getFriends)

            "Where are they from and how they came to be who they are."
            Field("secretBackstory", at: \.getSecretBackstory)
        }

        "A mechanical creature in the Star Wars universe."
        Type(Droid.self, implements: Character.self) {
            Field("id", of: String.self, at: \.id)
            Field("name", of: String.self, at: \.name)
            Field("appearsIn", of: [Episode].self, at: \.appearsIn)
            Field("primaryFunction", of: String.self, at: \.primaryFunction)

            "The friends of the droid, or an empty list if they have none."
            Field("friends", at: \.getFriends)

            "Where are they from and how they came to be who they are."
            Field("secretBackstory", at: \.getSecretBackstory)
        }

        Union(SearchResult.self, members: Planet.self, Human.self, Droid.self)

        Query {
            "Returns a hero based on the given episode."
            Field("hero", at: \.hero) {
                """
                If omitted, returns the hero of the whole saga.
                If provided, returns the hero of that particular episode.
                """
                Argument("episode", at: \.episode)
            }

            Field("human", at: \.human) {
                "Id of the human."
                Argument("id", at: \.id)
            }

            Field("droid", at: \.droid) {
                "Id of the droid."
                Argument("id", at: \.id)
            }

            Field("search", at: \.search) {
                Argument("query", at: \.query)
                    .defaultValue("R2-D2")
            }
        }

        #warning("TODO: Automatically add all types instead of having to manually define them here.")
        Types(Human.self, Droid.self, Planet.self)
    }
}

