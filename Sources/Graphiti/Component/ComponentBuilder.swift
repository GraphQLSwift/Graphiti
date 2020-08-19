@_functionBuilder
public struct ComponentBuilder<Resolver, Context> {
    public static func buildExpression(_ component: Component<Resolver, Context>) -> Component<Resolver, Context> {
        component
    }

    public static func buildBlock(_ components: Component<Resolver, Context>...) -> [Component<Resolver, Context>] {
        components
    }
}
