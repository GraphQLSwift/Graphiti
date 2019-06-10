import GraphQL

protocol TypeProvider : class {
    var graphQLTypeMap: [AnyType: GraphQLType] { get set }
}

extension TypeProvider {
    func map(_ type: Any.Type, to graphQLType: GraphQLType) throws {
        guard !(type is Void.Type) else {
            return
        }
        
        let key = AnyType(type)
        
        guard self.graphQLTypeMap[key] == nil else {
            throw GraphQLError(
                message: "Duplicate type registration: \(graphQLType.debugDescription)"
            )
        }
        
        self.graphQLTypeMap[key] = graphQLType
    }
    
    func getGraphQLOptionalType(from type: GraphQLType, isOptional: Bool) -> GraphQLType? {
        if isOptional {
            return type
        } else if let type = type as? GraphQLNullableType {
            return GraphQLNonNull(type)
        } else {
            // TODO: Throw error
            return nil
        }
    }
    
    func getGraphQLType(from type: Any.Type, isOptional: Bool = false) -> GraphQLType? {
        if let type = type as? Wrapper.Type {
            switch type.modifier {
            case .optional:
                return self.getGraphQLType(from: type.wrappedType, isOptional: true)
            case .list:
                return self.getGraphQLType(from: type.wrappedType).flatMap {
                    self.getGraphQLOptionalType(from: GraphQLList($0), isOptional: isOptional)
                }
            case .reference:
                let name = fixName(String(describing: type.wrappedType))
                let referenceType = GraphQLTypeReference(name)
                
                return self.getGraphQLOptionalType(from: referenceType, isOptional: isOptional)
            }
        } else {
            return graphQLTypeMap[AnyType(type)].flatMap {
                self.getGraphQLOptionalType(from: $0, isOptional: isOptional)
            }
        }
    }
    
    func getOutputType(from type: Any.Type, field: String) throws -> GraphQLOutputType {
        // TODO: Remove this when Reflection error is fixed
        guard isEncodable(type: type) else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not conform to \"MapFallibleRepresentable\"."
            )
        }
        
        guard let graphQLType = self.getGraphQLType(from: type) else {
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
                "Mapped GraphQL type is not an output type."
            )
        }
        
        return outputType
    }
    
    func getInputType(from type: Any.Type, field: String) throws -> GraphQLInputType {
        guard let graphQLType = self.getGraphQLType(from: type) else {
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
                "Mapped GraphQL type is not an input type."
            )
        }
        
        return inputType
    }
    
    func getNamedType(from type: Any.Type) throws -> GraphQLNamedType {
        guard let graphQLType = self.getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                "Cannot use type \"\(type)\" as named type. " +
                "Type does not map to a GraphQL type."
            )
        }
        
        guard let namedType = GraphQL.getNamedType(type: graphQLType) else {
            throw GraphQLError(
                message:
                "Cannot use type \"\(type)\" as named type. " +
                "Mapped GraphQL type is not a named type."
            )
        }
        
        return namedType
    }
    
    func getInterfaceType(from type: Any.Type) throws -> GraphQLInterfaceType {
        // TODO: Remove this when Reflection error is fixed
        guard isProtocol(type: type) else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Type is not a protocol."
            )
        }
        
        guard let graphQLType = self.getGraphQLType(from: type) else {
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
                "Mapped GraphQL type is not an interface type."
            )
        }
        
        return interfaceType
    }
    
    func getObjectType(from type: Any.Type) throws -> GraphQLObjectType {
        guard let graphQLType = self.getGraphQLType(from: type) else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Type does not map to a GraphQL type."
            )
        }
        
        guard let nonNull = graphQLType as? GraphQLNonNull else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Mapped GraphQL type is nullable."
            )
        }
        
        guard let objectType = nonNull.ofType as? GraphQLObjectType else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Mapped GraphQL type is not an object type."
            )
        }
        
        return objectType
    }
}
