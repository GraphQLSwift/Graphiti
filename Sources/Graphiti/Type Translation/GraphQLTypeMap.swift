import GraphQL

final class AnyType : Hashable {
    let type: Any.Type

    init(_ type: Any.Type) {
        self.type = type
    }

    var hashValue: Int {
        return String(describing: type).hashValue
    }

    static func == (lhs: AnyType, rhs: AnyType) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

var graphQLTypeMap: [AnyType: GraphQLType] = [
    AnyType(Int.self): GraphQLInt,
    AnyType(Double.self): GraphQLFloat,
    AnyType(String.self): GraphQLString,
    AnyType(Bool.self): GraphQLBoolean,
]

func link(_ type: Any.Type, to graphQLType: GraphQLType) {
    guard !(type is Void.Type) else {
        return
    }

    graphQLTypeMap[AnyType(type)] = graphQLType
}

func isProtocol(type: Any.Type) -> Bool {
    let description = String(describing: type(of: type))
    return description.hasSuffix("Protocol")
}

func fixName(_ name: String) -> String {
    if name.hasPrefix("(") {
        var newName: [Character] = []

        for character in String(name.characters.dropFirst()).characters {
            if character != " " {
                newName.append(character)
            } else {
                break
            }
        }

        return String(newName)
    }

    return name
}

func getGraphQLType(from type: Any.Type) -> GraphQLType? {
    if let type = type as? Wrapper.Type {
        switch type.modifier {
        case .optional:
            if let wrapper = type.wrappedType as? Wrapper.Type {
                if case .reference = wrapper.modifier {
                    let name = fixName(String(describing: wrapper.wrappedType))
                    return GraphQLTypeReference(name)
                } else {
                    return getGraphQLType(from: type.wrappedType)
                }
            } else {
                return graphQLTypeMap[AnyType(type.wrappedType)]
            }
        case .list:
            if type.wrappedType is Wrapper.Type {
                let unwrapped = getGraphQLType(from: type.wrappedType)
                return unwrapped.map { GraphQLList($0) }
            } else {
                let unwrapped = graphQLTypeMap[AnyType(type.wrappedType)]
                // TODO: check if it's nullable and throw error
                return unwrapped.map { GraphQLList(GraphQLNonNull($0 as! GraphQLNullableType)) }
            }
        case .reference:
            let name = fixName(String(describing: type.wrappedType))
            return GraphQLNonNull(GraphQLTypeReference(name))
        }
    }

    return graphQLTypeMap[AnyType(type)].flatMap {
        guard let nullable = $0 as? GraphQLNullableType else {
            return nil
        }

        return GraphQLNonNull(nullable)
    }
}

func isMapFallibleRepresentable(type: Any.Type) -> Bool {
    if isProtocol(type: type) {
        return true
    }

    if let type = type as? Wrapper.Type {
        return isMapFallibleRepresentable(type: type.wrappedType)
    }

    return type is MapFallibleRepresentable.Type
}

func getOutputType(from type: Any.Type, field: String) throws -> GraphQLOutputType {
    // TODO: Remove this when Reflection error is fixed
    guard isMapFallibleRepresentable(type: type) else {
        throw GraphQLError(
            message:
            // TODO: Add field type and use "type.field" format.
            "Cannot use type \"\(type)\" for field \"\(field)\". " +
            "Type does not conform to \"MapFallibleRepresentable\"."
        )
    }

    guard let graphQLType = getGraphQLType(from: type) else {
        throw GraphQLError(
            message:
            // TODO: Add field type and use "type.field" format.
            "Cannot use type \"\(type)\" for field \"\(field)\". " +
            "Type does not map to a GraphQL type."
        )
    }

    guard let outputType = graphQLType as? GraphQLOutputType else {
        throw GraphQLError(
            message:
            // TODO: Add field type and use "type.field" format.
            "Cannot use type \"\(type)\" for field \"\(field)\". " +
            "Mapped GraphQL type does is not an output type."
        )
    }

    return outputType
}

func getNamedType(from type: Any.Type) throws -> GraphQLNamedType {
    // TODO: Remove this when Reflection error is fixed
    guard let graphQLType = getGraphQLType(from: type) else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as a named type. " +
            "Type does not map to a GraphQL type."
        )
    }

    guard let nonNull = graphQLType as? GraphQLNonNull else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as a named type. " +
            "Mapped GraphQL type is nullable."
        )
    }

    guard let namedType = nonNull.ofType as? GraphQLNamedType else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as interface. " +
            "Mapped GraphQL type is not a named type."
        )
    }

    return namedType
}


func getInputType(from type: Any.Type, field: String) throws -> GraphQLInputType {
    guard let graphQLType = getGraphQLType(from: type) else {
        throw GraphQLError(
            message:
            // TODO: Add field type and use "type.field" format.
            "Cannot use type \"\(type)\" for field \"\(field)\". " +
            "Type does not map to a GraphQL type."
        )
    }

    guard let inputType = graphQLType as? GraphQLInputType else {
        throw GraphQLError(
            message:
            // TODO: Add field type and use "type.field" format.
            "Cannot use type \"\(type)\" for field \"\(field)\". " +
            "Mapped GraphQL type does is not an output type."
        )
    }

    return inputType
}

func getInterface(from type: Any.Type) throws -> GraphQLInterfaceType {
    // TODO: Remove this when Reflection error is fixed
    guard isProtocol(type: type) else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as interface. " +
            "Type does is not a protocol."
        )
    }

    guard let graphQLType = getGraphQLType(from: type) else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as interface. " +
            "Type does not map to a GraphQL type."
        )
    }

    guard let nonNull = graphQLType as? GraphQLNonNull else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as interface. " +
            "Mapped GraphQL type is nullable."
        )
    }

    guard let interfaceType = nonNull.ofType as? GraphQLInterfaceType else {
        throw GraphQLError(
            message:
            // TODO: Add more information of where the error happened.
            "Cannot use type \"\(type)\" as interface. " +
            "Mapped GraphQL type does is not an interface type."
        )
    }
    
    return interfaceType
}
