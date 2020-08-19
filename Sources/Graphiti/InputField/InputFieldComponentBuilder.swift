@_functionBuilder
public struct InputFieldComponentBuilder<InputObjectType, Context> {
    public static func buildExpression(_ component: InputFieldComponent<InputObjectType, Context>) -> InputFieldComponent<InputObjectType, Context> {
        component
    }

    public static func buildBlock(_ components: InputFieldComponent<InputObjectType, Context>...) -> [InputFieldComponent<InputObjectType, Context>] {
        components
    }
}
