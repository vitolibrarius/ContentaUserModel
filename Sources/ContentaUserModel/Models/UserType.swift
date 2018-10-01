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

    // MARK: - attributes
    public var code: ID?
    public var displayName: String
    
    /// Creates a new `User`.
    init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }
}

// MARK: - Relations

// UserType ↤⇉ User
extension UserType {
    public var users: Children<UserType, User<Database>> {
        return children(\User.typeCode)
    }
}

// MARK: queries
extension UserType {
    public static func forCode( _ code : String, on connection: Database.Connection ) throws -> UserType? {
        let matches = try UserType.query(on: connection).filter(\UserType.code == code).all().wait()
        return matches.first
    }
}
