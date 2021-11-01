@resultBuilder
public struct DirectiveLocationBuilder<DirectiveType> {
    public static func buildExpression(_ value: DirectiveLocation<DirectiveType>) -> DirectiveLocation<DirectiveType> {
        value
    }

    public static func buildBlock(_ value: DirectiveLocation<DirectiveType>...) -> [DirectiveLocation<DirectiveType>] {
        value
    }
}

