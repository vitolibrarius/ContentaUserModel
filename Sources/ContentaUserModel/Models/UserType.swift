//
//  UserType.swift
//

import Async
import Fluent
import Foundation

public final class UserType<D>: Model where D: QuerySupporting {
    // MARK: ID
    public typealias ID = String
    public typealias Database = D
    public static var idKey: IDKey { return \.code }
    public static var entity: String {
        return "user_type"
    }
    public static var database: DatabaseIdentifier<D> {
        return .init("user_types")
    }
    
    public var code: ID?
    public var displayName: String
    
    /// Creates a new `User`.
    init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }
}
