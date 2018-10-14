//
//  User.swift
//

import Foundation
import Async
import Fluent
import Crypto
import Authentication
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
    public var failedLogins: Int? = 0
    public var active: Bool? = true

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
}

// MARK: - Content - Parameter
extension User: Content {}
extension User: Parameter {}

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

extension User where D: JoinSupporting {
    public var networkJoins: Siblings<User, Network<Database>, UserNetworkJoin<Database>> {
        return siblings()
    }

    public func isAttachedToNetwork(_ network: Network<Database>, on connection: DatabaseConnectable  ) throws -> Future<Bool> {
        return networkJoins.isAttached(network, on: connection)
    }

    public func isAttachedToAddress(_ ipaddress: IPAddress, on connection: DatabaseConnectable  ) throws -> Future<Bool> {
        return try Network<Database>.forIPAddress( ipaddress, on: connection ).flatMap { nwork in
            guard let network = nwork else { return Future.map(on: connection) { false }}
            return self.networkJoins.isAttached(network, on: connection)
        }
    }

    public func addAddressIfAbsent(_ ipaddress: IPAddress, on connection: DatabaseConnectable  ) throws -> Future<Network<Database>> {
        return try Network<Database>.findOrCreateIPAddress(ipaddress, on: connection).flatMap { nwork in
            return try self.addNetworkIfAbsent(nwork, on: connection)
        }
    }

    public func addNetworkIfAbsent(_ network: Network<Database>, on connection: DatabaseConnectable ) throws -> Future<Network<Database>> {
        return try isAttachedToNetwork(network, on: connection).flatMap { isAttached in
            if ( isAttached == false ) {
                _ = self.networkJoins.attach(network, on: connection)
            }
            return Future.map(on: connection) { network }
        }
    }
}

// MARK: - queries
extension User {
    public static func forUsername( _ username : String, on connection: DatabaseConnectable ) throws -> Future<User?> {
        return Future.flatMap(on: connection) {
            return User.query(on: connection).filter(\User.username == username).first().map { usr in
                return usr ?? nil
            }
        }
    }

    public static func forEmail( _ email : String, on connection: DatabaseConnectable ) throws -> Future<User?> {
        return Future.flatMap(on: connection) {
            return User.query(on: connection).filter(\User.email == email).first().map { usr in
                return usr ?? nil
            }
        }
    }

    public static func forUsernameOrEmail( username : String, email : String, on connection: DatabaseConnectable ) throws -> Future<[User]> {
        return User<Database>.query(on: connection).group(Database.queryFilterRelationOr, closure: { or in
            or.filter(\User.username == username)
            or.filter(\User.email == email)
        }).all()
    }

    public func tokenFor( type: AccessTokenType<Database>, on connection: DatabaseConnectable ) throws -> Future<AccessToken<Database>?> {
        return try AccessToken.tokenFor( user: self, andType: type, on: connection )
    }
    
    public func findOrCreateToken( type: AccessTokenType<Database>, on connection: DatabaseConnectable ) throws -> Future<AccessToken<Database>> {
        return try AccessToken<Database>.findOrCreateToken( user: self, andType: type, on: connection )
    }
}

// MARK: - Lifecycle
extension User {
    public func willCreate(on connection: DatabaseConnectable) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }
    public func didCreate(on connection: DatabaseConnectable) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }

    public func willUpdate(on connection: DatabaseConnectable) throws -> Future<User> {
        /// Throws an error if the username is invalid
        //try validateUsername()
        
        /// Return the user. No async work is being done, so we must create a future manually.
        return Future.map(on: connection) { self }
    }
    public func didUpdate(on connection: DatabaseConnectable) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }

    public func willRead(on connection: DatabaseConnectable) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }

    public func willDelete(on connection: DatabaseConnectable) throws -> Future<User> {
        return Future.map(on: connection) { self }
    }
}

// MARK: - Basic Authentication
extension User: BasicAuthenticatable {
    public var password : String {
        get {
            return self.passwordHash != nil ? self.passwordHash! : ""
        }
        set {
            do {
                try Validator<String>.password.validate(newValue)
                self.passwordHash = try BCrypt.hash(newValue) // 12 iterations, random salt
            }
            catch  {
                print(error.localizedDescription)
            }
        }
    }
    public static var usernameKey: UsernameKey {
        return \User<Database>.username
    }
    
    public static var passwordKey: PasswordKey {
        return \User<Database>.password
    }
}
