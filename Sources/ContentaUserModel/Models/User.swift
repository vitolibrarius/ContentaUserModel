//
//  User.swift
//

import Async
import Fluent
import Foundation

public final class User<D>: Model where D: QuerySupporting {

    // MARK: ID
    public typealias ID = Int
    public typealias Database = D
    public static var idKey: IDKey { return \.id }
    public static var entity: String {
        return "user"
    }
    public static var database: DatabaseIdentifier<D> {
        return .init("users")
    }

    public var id: ID?
    public var username: String
    public var email: String
    public var active: Bool = true
    public var created: Date?
    
    /// Creates a new `User`.
    init(username: String, email: String) {
        self.username = username
        self.email = email
        self.created = Date()
    }
}

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
