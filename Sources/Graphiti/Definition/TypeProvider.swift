import GraphQL

protocol TypeProvider : class {
    var graphQLTypeMap: [AnyType: GraphQLType] { get set }
}

extension TypeProvider {
    func contains(type: Any.Type) -> Bool {
        graphQLTypeMap[AnyType(type)] == nil
    }
    
    func map(_ type: Any.Type, to graphQLType: GraphQLType) throws {
        guard !(type is Void.Type) else {
            return
        }
        
        let key = AnyType(type)
        
        guard graphQLTypeMap[key] == nil else {
            throw GraphQLError(
                message: "Duplicate type registration for GraphQLType \"\(graphQLType.debugDescription)\" while trying to register type \(Reflection.name(for: type))"
            )
        }
        
        graphQLTypeMap[key] = graphQLType
    }
    
    func getGraphQLOptionalType(from type: GraphQLType, isOptional: Bool) throws -> GraphQLType {
        if isOptional {
            return type
        } else if let type = type as? GraphQLNullableType {
            return GraphQLNonNull(type)
        } else {
            throw GraphQLError(
                message:
                "GraphQLType \"\(type)\" is not nullable."
            )
        }
    }
    
    func getGraphQLType(from type: Any.Type, isOptional: Bool = false) throws -> GraphQLType {
        if let type = type as? Wrapper.Type {
            switch type.modifier {
            case .optional:
                return try getGraphQLType(from: type.wrappedType, isOptional: true)
            case .list:
                let graphQLType = try getGraphQLType(from: type.wrappedType)
                return try getGraphQLOptionalType(from: GraphQLList(graphQLType), isOptional: isOptional)
            case .reference:
                let name = Reflection.name(for: type.wrappedType)
                let referenceType = GraphQLTypeReference(name)
                
                return try getGraphQLOptionalType(from: referenceType, isOptional: isOptional)
            }
        } else {
            guard let graphQLType = graphQLTypeMap[AnyType(type)] else {
                throw GraphQLError(message: "Type \"\(type)\" is not registered.")
            }
            
            return try getGraphQLOptionalType(from: graphQLType, isOptional: isOptional)
        }
    }
    
    func getOutputType(from type: Any.Type, field: String) throws -> GraphQLOutputType {
        // TODO: Remove this when Reflection error is fixed
        guard Reflection.isEncodable(type: type) else {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not conform to \"Encodable\"."
            )
        }
        
        let graphQLType: GraphQLType
        
        do {
            graphQLType = try getGraphQLType(from: type)
        } catch {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not map to a GraphQL type.",
                originalError: error
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
        let graphQLType: GraphQLType
        
        do {
            graphQLType = try getGraphQLType(from: type)
        } catch {
            throw GraphQLError(
                message:
                // TODO: Add field type and use "type.field" format.
                "Cannot use type \"\(type)\" for field \"\(field)\". " +
                "Type does not map to a GraphQL type.",
                originalError: error
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
        let graphQLType: GraphQLType
        
        do {
            graphQLType = try getGraphQLType(from: type)
        } catch {
            throw GraphQLError(
                message:
                "Cannot use type \"\(type)\" as named type. " +
                "Type does not map to a GraphQL type.",
                originalError: error
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
        guard Reflection.isProtocol(type: type) else {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Type is not a protocol."
            )
        }
        
        let graphQLType: GraphQLType
        
        do {
            graphQLType = try getGraphQLType(from: type)
        } catch {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as interface. " +
                "Type does not map to a GraphQL type.",
                originalError: error
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
        let graphQLType: GraphQLType
        
        do {
            graphQLType = try getGraphQLType(from: type)
        } catch {
            throw GraphQLError(
                message:
                // TODO: Add more information of where the error happened.
                "Cannot use type \"\(type)\" as object. " +
                "Type does not map to a GraphQL type.",
                originalError: error
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
