@resultBuilder
public struct FieldComponentBuilder<ObjectType, Context> {
    public static func buildExpression(_ component: FieldComponent<ObjectType, Context>) -> FieldComponent<ObjectType, Context> {
        component
    }

    public static func buildBlock(_ components: FieldComponent<ObjectType, Context>...) -> [FieldComponent<ObjectType, Context>] {
        components
    }
}
