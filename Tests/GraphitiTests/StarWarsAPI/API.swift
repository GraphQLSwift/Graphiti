import Graphiti

public struct StarWarsAPI : API {
    public let root = Root()
    public let context = Store()
    
    public init() {}
    
    public let schema = try! Schema<Root, Store>(
        Enum(Episode.self,
            Value(.newHope)
                .description("Released in 1977."),
            
            Value(.empire)
                .description("Released in 1980."),
            
            Value(.jedi)
                .description("Released in 1983.")
        )
        .description("One of the films in the Star Wars Trilogy."),

        Interface(AnyCharacter.self,
            Field(\.id, as: .id)
                .description("The id of the character."),

            Field(\.name, as: .name)
                .description("The name of the character."),

            Field(\.friends, as: .friends, overridingType: [TypeReference<Character>].self)
                .description("The friends of the character, or an empty list if they have none."),

            Field(\.appearsIn, as: .appearsIn)
                .description("Which movies they appear in."),

            Field(\.secretBackstory, as: .secretBackstory)
                .description("All secrets about their past.")
        )
        .description("A character in the Star Wars Trilogy."),

        Type(Planet.self,
            Field(\.id, as: .id),
            Field(\.name, as: .name),
            Field(\.diameter, as: .diameter),
            Field(\.rotationPeriod, as: .rotationPeriod),
            Field(\.orbitalPeriod, as: .orbitalPeriod),
            Field(\.residents, as: .residents, overridingType: [TypeReference<Human>].self)
        )
        .description("A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY."),

        Type(Human.self, interfaces: [Character.self],
            Field(\.id, as: .id),
            Field(\.name, as: .name),
            Field(\.appearsIn, as: .appearsIn),
            Field(\.homePlanet, as: .homePlanet),

            Field(Human.getFriends, as: .friends)
                .description("The friends of the human, or an empty list if they have none."),

            Field(Human.getSecretBackstory, as: .secretBackstory)
                .description("Where are they from and how they came to be who they are.")
        )
        .description("A humanoid creature in the Star Wars universe."),

        Type(Droid.self, interfaces: [Character.self],
            Field(\.id, as: .id),
            Field(\.name, as: .name),
            Field(\.appearsIn, as: .appearsIn),
            Field(\.primaryFunction, as: .primaryFunction),

            Field(Droid.getFriends, as: .friends)
                .description("The friends of the droid, or an empty list if they have none."),

            Field(Droid.getSecretBackstory, as: .secretBackstory)
                .description("Where are they from and how they came to be who they are.")
        )
        .description("A mechanical creature in the Star Wars universe."),

        Union(SearchResult.self, members: Planet.self, Human.self, Droid.self),

        Query(
            Field(Root.hero, as: .hero,
                Argument(\.episode, as: .episode)
                    .description("If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.")
            )
            .description("Returns a hero based on the given episode."),


            Field(Root.human, as: .human,
                Argument(\.id, as: .id)
                    .description("Id of the human.")
            ),

            Field(Root.droid, as: .droid,
                Argument(\.id, as: .id)
                    .description("Id of the droid.")
            ),

            Field(Root.search, as: .search,
                Argument(\.query, as: .query)
                    .defaultValue("R2-D2")
            )
        ),

        Types(Human.self, Droid.self)
    )
}
