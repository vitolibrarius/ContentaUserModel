//
//  AccessToken.swift
//


import Async
import Fluent
import Foundation
import Crypto
import Vapor
import Validation

public final class AccessToken<D>: Model where D: JoinSupporting {
    // MARK: ID
    public typealias ID = Int
    public typealias Database = D
    public typealias Token = String

    public static var idKey: IDKey { return \.id }
    public static var entity: String {
        return "access_token"
    }
    public static var createdAtKey: TimestampKey? {
        return \AccessToken.created
    }
    public static var updatedAtKey: TimestampKey? {
        return \AccessToken.updated
    }

    // MARK: - attributes
    public var id: ID?
    public var typeCode: AccessTokenType<Database>.ID
    public var userId: User<Database>.ID
    public var token: Token
    
    public var created: Date?
    public var updated: Date?
    public var expires: Date?

    /// Creates a new `AccessToken`.
    init(type: AccessTokenType<Database>, user: User<Database>) throws {
        self.userId = try user.requireID()
        self.typeCode = try type.requireID()
        self.token = try CryptoRandom().generateData(count: 32).base64URLEncodedString()
        self.expires = Date().addingTimeInterval(type.tokenExpirationInterval)
    }
    
    public var isExpired : Bool {
        get {
            return self.expires != nil && self.expires! < Date()
        }
        set {
            if newValue {
                self.expires = Date().addingTimeInterval(-1000)
            }
        }
    }
}

// MARK: - Relations

// AccessToken ⇇↦  AccessTokenType
extension AccessToken {
    public var type: Parent<AccessToken, AccessTokenType<Database>> {
        return parent(\AccessToken.typeCode)
    }

    public var user: Parent<AccessToken, User<Database>> {
        return parent(\AccessToken.userId)
    }
}

// MARK: queries
extension AccessToken {
    public static func forToken( _ token : Token, on connection: DatabaseConnectable ) throws -> Future<AccessToken?> {
        return Future.flatMap(on: connection) {
            return AccessToken.query(on: connection).filter(\AccessToken.token == token).first().map { tok in
                return tok ?? nil
            }
        }
    }

    public static func allForUser( _ user : User<Database>, on connection: DatabaseConnectable ) throws -> Future<[AccessToken]> {
        let matches = try AccessToken.query(on: connection)
            .filter(\AccessToken.userId == user.requireID())
            .all()
        return matches
    }

    public static func tokenFor( user : User<Database>, andType type: AccessTokenType<Database>, on connection: DatabaseConnectable ) throws -> Future<AccessToken?> {
        return Future.flatMap(on: connection) {
            return try AccessToken.query(on: connection)
                .filter(\AccessToken.userId == user.requireID())
                .filter(\AccessToken.typeCode == type.requireID())
                .first()
                .map { tok in return tok ?? nil }
        }
    }
    public static func findOrCreateToken( user : User<Database>, andType type: AccessTokenType<Database>, on connection: DatabaseConnectable ) throws -> Future<AccessToken> {
        return try AccessToken<Database>.tokenFor( user: user, andType: type, on: connection ).flatMap { t in
            guard let token = t else {
                return try AccessToken(type: type, user: user).create(on: connection)
            }
            return Future.map(on: connection) { token }
        }
    }
}

// MARK: - Content - Parameter
extension AccessToken: Content {}
extension AccessToken: Parameter {}

// MARK: - Lifecycle
extension AccessToken {
    public func willCreate(on connection: DatabaseConnectable) throws -> Future<AccessToken> {
        try self.validate()
        return Future.map(on: connection) { self }
    }
    public func didCreate(on connection: DatabaseConnectable) throws -> Future<AccessToken> {
        return Future.map(on: connection) { self }
    }
    
    public func willUpdate(on connection: DatabaseConnectable) throws -> Future<AccessToken> {
        try self.validate()
        return Future.map(on: connection) { self }
    }
    public func didUpdate(on connection: DatabaseConnectable) throws -> Future<AccessToken> {
        return Future.map(on: connection) { self }
    }
    
    public func willRead(on connection: DatabaseConnectable) throws -> Future<AccessToken> {
        return Future.map(on: connection) { self }
    }
    
    public func willDelete(on connection: DatabaseConnectable) throws -> Future<AccessToken> {
        return Future.map(on: connection) { self }
    }
}

extension AccessToken : Validatable, Reflectable {    
    public static func validations() throws -> Validations<AccessToken<D>> {
        let validations = Validations(AccessToken.self)
        return validations
    }
}
