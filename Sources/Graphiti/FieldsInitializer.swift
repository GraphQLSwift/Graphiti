import NIO

public final class FieldsInitializer<ObjectType, Keys : RawRepresentable, Context> where Keys.RawValue == String {
    var fields: [FieldComponent<ObjectType, Keys, Context>] = []
    
    @discardableResult
    public func field<ResolveType>(
        _ name: Keys,
        at keyPath: KeyPath<ObjectType, ResolveType>
    ) -> FieldInitializer<ObjectType, Keys, Context, NoArguments> {
        let field = Field<ObjectType, Keys, Context, NoArguments, ResolveType, ResolveType>(name: name.rawValue) { (type: ObjectType) in
            return { (context: Context, arguments: NoArguments) in
                return type[keyPath: keyPath]
            }
        }
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    // Adds native support for Set by converting resolve type to Array.
    @discardableResult
    public func field<ResolveType>(
        _ name: Keys,
        at keyPath: KeyPath<ObjectType, Set<ResolveType>>
    ) -> FieldInitializer<ObjectType, Keys, Context, NoArguments> {
        let field = Field<ObjectType, Keys, Context, NoArguments, Set<ResolveType>, Array<ResolveType>>(name: name.rawValue) { (type: ObjectType) in
            return { (context: Context, arguments: NoArguments) in
                return Array(type[keyPath: keyPath])
            }
        }
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    @discardableResult
    public func field<FieldType, ResolveType>(
        _ name: Keys,
        at keyPath: KeyPath<ObjectType, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    ) -> FieldInitializer<ObjectType, Keys, Context, NoArguments> {
        let name = name.rawValue
        
        let function: SyncResolve<ObjectType, Context, NoArguments, ResolveType> = { type in
            return { context, arguments in
                return type[keyPath: keyPath]
            }
        }
        
        let field = Field<ObjectType, Keys, Context, NoArguments, FieldType, ResolveType>(
            name: name,
            at: function
        )
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    @discardableResult
    public func field<FieldType, ResolveType>(
        _ name: Keys,
        at function: @escaping SyncResolve<ObjectType, Context, NoArguments, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    ) -> FieldInitializer<ObjectType, Keys, Context, NoArguments> {
        let field = Field<ObjectType, Keys, Context, NoArguments, FieldType, ResolveType>(
            name: name.rawValue,
            at: function
        )
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    @discardableResult
    public func field<FieldType, ResolveType>(
        _ name: Keys,
        at function: @escaping AsyncResolve<ObjectType, Context, NoArguments, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    ) -> FieldInitializer<ObjectType, Keys, Context, NoArguments> {
        let field = Field<ObjectType, Keys, Context, NoArguments, FieldType, ResolveType>(
            name: name.rawValue,
            at: function
        )
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    @discardableResult
    public func field<Arguments : Decodable, ResolveType>(
        _ name: Keys,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) -> FieldInitializer<ObjectType, Keys, Context, Arguments> {
        let field = Field<ObjectType, Keys, Context, Arguments, ResolveType, ResolveType>(
            name: name.rawValue,
            at: function
        )
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    @discardableResult
    public func field<Arguments : Decodable, ResolveType>(
        _ name: Keys,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) -> FieldInitializer<ObjectType, Keys, Context, Arguments> {
        let field = Field<ObjectType, Keys, Context, Arguments, ResolveType, ResolveType>(
            name: name.rawValue,
            at: function
        )
        
        fields.append(field)
        return FieldInitializer(field)
    }
    
    @discardableResult
    public func field<FieldType, ResolveType>(
        _ name: Keys,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, NoArguments, ResolveType>,
        overridingType: FieldType.Type = FieldType.self
    ) -> FieldInitializer<ObjectType, Keys, Context, NoArguments> {
        let asyncResolve: AsyncResolve<ObjectType, Context, NoArguments, ResolveType> = { type in
            return { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try function(type)(context, arguments).hop(to: group.next())
            }
        }
        
        return field(name, at: asyncResolve, overridingType: overridingType)
    }
    
    @discardableResult
    public func field<Arguments : Decodable, ResolveType>(
        _ name: Keys,
        at function: @escaping SimpleAsyncResolve<ObjectType, Context, Arguments, ResolveType>
    ) -> FieldInitializer<ObjectType, Keys, Context, Arguments> {
        let asyncResolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            return { context, arguments, group in
                // We hop to guarantee that the future will
                // return in the same event loop group of the execution.
                try function(type)(context, arguments).hop(to: group.next())
            }
        }
        
        return field(name, at: asyncResolve)
    }
}
