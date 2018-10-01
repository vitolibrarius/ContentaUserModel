//
//  User.swift
//

import Async
import Fluent
import Foundation
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

    // MARK: - attributes
    public var id: ID?
    public var typeCode: String
    public var username: String
    public var email: String
    public var active: Bool = true
    public var created: Date?
    public var updated: Date?

    /// Creates a new `User`.
    init(username: String, email: String, type: String) {
        self.typeCode = type
        self.username = username
        self.email = email
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
    public func tokenFor( type: AccessTokenType<Database>, on connection: Database.Connection ) throws -> AccessToken<Database>? {
        return try AccessToken.tokenFor( user: self, andType: type, on: connection )
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
