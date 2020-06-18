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
}
