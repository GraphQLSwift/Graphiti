@resultBuilder
public enum TypeComponentBuilder<Resolver, Context> {
    public static func buildExpression(
        _ component: TypeComponent<Resolver, Context>
    ) -> TypeComponent<Resolver, Context> {
        component
    }

    public static func buildBlock(
        _ components: TypeComponent<Resolver, Context>...
    ) -> [TypeComponent<Resolver, Context>] {
        components
    }
}
