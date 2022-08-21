@resultBuilder
public struct ArgumentComponentBuilder<ArgumentsType: Decodable> {
    public static func buildExpression(
        _ component: ArgumentComponent<ArgumentsType>
    ) -> ArgumentComponent<ArgumentsType> {
        component
    }

    public static func buildBlock(
        _ components: ArgumentComponent<ArgumentsType>...
    ) -> [ArgumentComponent<ArgumentsType>] {
        components
    }
}
