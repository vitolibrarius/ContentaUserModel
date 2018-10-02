//
//  User.swift
//

import Foundation
import Async
import Fluent
import Crypto
import Validation
import ContentaTools

public final class User<D>: Model where D: QuerySupporting {

    // MARK: ID
    public typealias ID = Int
    public typealias Database = D
    public static var idKey: IDKey { return \.id }

    public static var entity: String {
        return "user"
    }

    public static var createdAtKey: TimestampKey? {
        return \User.created
    }
    public static var updatedAtKey: TimestampKey? {
        return \User.updated
    }

    // MARK: - PK, FK attributes
    public var id: ID?
    public var typeCode: String
    
    // MARK: - auth attributes
    public var username: String
    public var passwordHash: String?
    public var failedLogins: Int = 0
    public var active: Bool = true

    // MARK: - user meta attributes
    public var fullname: String
    public var email: String

    // MARK: - timestamp attributes
    public var created: Date?
    public var updated: Date?
    public var lastLogin: Date?
    public var lastFailedLogin: Date?

    /// Creates a new `User`.
    init(name: String, username: String, email: String, type: String) {
        self.typeCode = type
        self.username = username
        self.fullname = name
        self.email = email
    }

    public func changePassword(_ password: String, on connection: Database.Connection ) throws -> EventLoopFuture<User> {
        // validate
        try Validator<String>.password.validate(password)

        self.passwordHash = try BCrypt.hash(password) // 12 iterations, random salt
        return self.save(on: connection)
    }

    public func passwordVerify(_ password: String) throws -> Bool {
        if self.passwordHash == nil {
            return false
        }
        return try BCrypt.verify(password, created: self.passwordHash!)
    }
}

// MARK: - validation
extension User : Validatable {
    public static func validations() throws -> Validations<User<D>> {
        var validations = Validations(User.self)
        try validations.add( \User.username, Validator<String>.alphanumeric)
        try validations.add( \User.email, Validator<String>.email)
        return validations
    }
    
}

// MARK: - Relations

// User ⇇↦  UserType
extension User {
    public var type: Parent<User, UserType<Database>> {
        return parent(\User.typeCode)
    }
}

// User ↤⇉ AccessTokens
extension User {
    public var accessTokens: Children<User, AccessToken<Database>> {
        return children(\AccessToken.userId)
    }
}

// MARK: queries
extension User {
    public static func forUsername( _ username : String, on connection: Database.Connection ) throws -> User? {
        let matches = try User.query(on: connection).filter(\User.username == username).all().wait()
        return matches.first
    }

    public func tokenFor( type: AccessTokenType<Database>, on connection: Database.Connection ) throws -> AccessToken<Database>? {
        return try AccessToken.tokenFor( user: self, andType: type, on: connection )
    }

    public func findOrCreateToken( type: AccessTokenType<Database>, on connection: Database.Connection ) throws -> AccessToken<Database> {
        return try AccessToken<Database>.findOrCreateToken( user: self, andType: type, on: connection )
    }
}

extension User where D: JoinSupporting {
    public var networkJoins: Siblings<User, Network<Database>, UserNetworkJoin<Database>> {
        return siblings()
    }

    public func isAttachedToNetwork(_ network: Network<Database>, on connection: Database.Connection  ) throws -> Bool {
        return try networkJoins.isAttached(network, on: connection).wait()
    }

    public func isAttachedToAddress(_ ipaddress: IPAddress, on connection: Database.Connection  ) throws -> Bool {
        guard let network : Network<Database> = try Network<Database>.forIPAddress( ipaddress, on: connection ) else {
            return false
        }
        return try networkJoins.isAttached(network, on: connection).wait()
    }
    
    public func addAddressIfAbsent(_ ipaddress: IPAddress, on connection: Database.Connection ) throws -> Network<Database> {
        let network : Network<D> = try Network<Database>.findOrCreateIPAddress( ipaddress, on: connection )
        return try addNetworkIfAbsent(network, on: connection)
    }

    public func addNetworkIfAbsent(_ network: Network<Database>, on connection: Database.Connection ) throws -> Network<Database> {
        if try isAttachedToNetwork(network, on: connection) == false {
            _ = networkJoins.attach(network, on: connection)
        }
        return network
    }
}

// MARK: - Lifecycle
extension User {
    public func willCreate(on connection: Database.Connection) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }
    public func didCreate(on connection: Database.Connection) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }

    public func willUpdate(on connection: Database.Connection) throws -> Future<User> {
        /// Throws an error if the username is invalid
        //try validateUsername()
        
        /// Return the user. No async work is being done, so we must create a future manually.
        return Future.map(on: connection) { self }
    }
    public func didUpdate(on connection: Database.Connection) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }

    public func willRead(on connection: Database.Connection) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }

    public func willDelete(on connection: Database.Connection) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }
}
