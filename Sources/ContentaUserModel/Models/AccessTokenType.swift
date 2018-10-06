//
//  AccessTokenType.swift
//

import Async
import Fluent
import Foundation
import Vapor
import Validation

public final class AccessTokenType<D>: Model where D: QuerySupporting {
    // MARK: ID
    public typealias ID = String
    public typealias Database = D
    public static var idKey: IDKey { return \.code }
    public static var entity: String {
        return "access_token_type"
    }

    // MARK: - attributes
    public var code: ID?
    public var displayName: String
    public var tokenExpirationInterval: TimeInterval = 3600

    /// Creates a new `AccessTokenType`.
    init(code: String, displayName: String, expires: TimeInterval) {
        self.code = code
        self.displayName = displayName
        self.tokenExpirationInterval = expires
    }
}

// MARK: - Relations

// AccessTokenType ↤⇉ AccessToken
extension AccessTokenType {
    public var accessTokens: Children<AccessTokenType, AccessToken<Database>> {
        return children(\AccessToken.typeCode)
    }
}

// MARK: queries
extension AccessTokenType {
    public static func forCode( _ code : String, on connection: Database.Connection ) throws -> Future<AccessTokenType?> {
        return Future.flatMap(on: connection) {
            return AccessTokenType.query(on: connection).filter(\AccessTokenType.code == code).first().map { tok in
                return tok ?? nil
            }
        }
    }
}

// MARK: - Content - Parameter
extension AccessTokenType: Content {}
extension AccessTokenType: Parameter {}
