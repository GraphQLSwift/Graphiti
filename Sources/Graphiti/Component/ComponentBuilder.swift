@_functionBuilder
public struct ComponentBuilder<RootType, Context> {
    public static func buildExpression(_ component: Component<RootType, Context>) -> Component<RootType, Context> {
        component
    }

    public static func buildBlock(_ component: Component<RootType, Context>) -> [Component<RootType, Context>] {
        [component]
    }

    public static func buildBlock(_ components: Component<RootType, Context>...) -> [Component<RootType, Context>] {
        components
    }
}
