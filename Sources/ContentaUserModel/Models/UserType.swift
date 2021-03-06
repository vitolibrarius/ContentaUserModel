//
//  UserType.swift
//

import Async
import Fluent
import Foundation
import Vapor
import Validation

public final class UserType<D>: Model where D: JoinSupporting {
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
    public var defaultType: Bool = false

    /// Creates a new `User`.
    init(code: String, displayName: String) {
        self.code = code
        self.displayName = displayName
    }

    public var isDefaultType : Bool {
        get {
            return defaultType
        }
        set {
            self.defaultType = newValue
        }
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
    public static func forCode( _ code : String, on connection: DatabaseConnectable ) throws -> Future<UserType?> {
        return Future.flatMap(on: connection) {
            return UserType.query(on: connection).filter(\UserType.code == code).first().map { type in
                return type ?? nil
            }
        }
    }

    public static func defaultTypeCode( on connection: DatabaseConnectable ) throws -> Future<UserType?> {
        return Future.flatMap(on: connection) {
            return UserType.query(on: connection).filter(\UserType.defaultType == true).first().map { type in
                return type ?? nil
            }
        }
    }
}

// MARK: - Content - Parameter
extension UserType: Content {}
extension UserType: Parameter {}

extension UserType: Equatable {
    public static func == (lhs: UserType<D>, rhs: UserType<D>) -> Bool {
        do {
            let lhsId = try lhs.requireID()
            let rhsId = try rhs.requireID()
            return lhsId == rhsId
        }
        catch  {
            return false
        }
    }
}
