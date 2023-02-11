@resultBuilder
public enum KeyComponentBuilder<ObjectType, Resolver, Context> {
    public static func buildExpression(
        _ component: KeyComponent<ObjectType, Resolver, Context>
    ) -> KeyComponent<ObjectType, Resolver, Context> {
        component
    }

    public static func buildBlock(
        _ components: KeyComponent<ObjectType, Resolver, Context>...
    ) -> [KeyComponent<ObjectType, Resolver, Context>] {
        components
    }
}
