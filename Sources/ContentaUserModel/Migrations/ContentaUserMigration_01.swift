// 

import Foundation
import Fluent
import ContentaTools

public struct ContentaUserMigration_01<D> : Migration where D: JoinSupporting & SchemaSupporting & MigrationSupporting {
    public typealias Database = D

    // MARK: - seed data
    static func sample_userTypes() -> [[String:String]] {
        return [
            [ "code": "UNR",   "displayName": "Unregistered" ],
            [ "code": "REG",   "displayName": "Registered", "defaultType": "true" ],
            [ "code": "ADMIN", "displayName": "Administrator" ]
        ]
    }

    static func sample_addresses() -> [IPAddress] {
        return [ IPAddress("127.0.0.1")!, IPAddress("fe80::1")! ]
    }

    static func sample_users() -> [[String:String]] {
        return [
            [ "name": "Vito Librarius", "username": "vitolib",  "type": "ADMIN", "email": "vitolibrarius@gmail.com", "password": "TeSt12345" ],
            [ "name": "Clark Kent",     "username": "superman", "type": "REG",   "email": "clark.kent@gmail.com",    "password": "Chang3 m3 pleas3" ]
        ]
    }

    // MARK: - create tables
    static func prepareTableUserType(on connection: Database.Connection) -> Future<Void> {
        return Database.create(UserType.self, on: connection) { builder in
            
            //add fields
            builder.field(for: \UserType.code, isIdentifier: true)
            builder.field(for: \UserType.displayName)
            builder.field(for: \UserType.defaultType)
        }
    }

    static func prepareTableNetwork(on connection: Database.Connection) -> Future<Void> {
        return Database.create(Network.self, on: connection) { builder in
            
            //add fields
            builder.field(for: \Network.id, isIdentifier: true)
            builder.field(for: \Network.ipAddress)
            builder.field(for: \Network.ipHash)
            builder.field(for: \Network.active)
            builder.field(for: \Network.created)
            
            // constraints
            builder.unique(on: \Network.ipAddress )
        }
    }

    static func prepareTableUser(on connection: Database.Connection) -> Future<Void> {
        return Database.create(User.self, on: connection) { builder in
            
            //add fields
            builder.field(for: \User.id, isIdentifier: true)
            builder.field(for: \User.typeCode)
            builder.field(for: \User.username)
            builder.field(for: \User.passwordHash)
            builder.field(for: \User.failedLogins)
            builder.field(for: \User.fullname)
            builder.field(for: \User.email)
            builder.field(for: \User.active)
            builder.field(for: \User.created)
            builder.field(for: \User.updated)
            builder.field(for: \User.lastLogin)
            builder.field(for: \User.lastFailedLogin)

            builder.reference(from: \User.typeCode, to: \UserType<Database>.code)
            
            // constraints
            builder.unique(on: \.email )
            builder.unique(on: \.username )
        }
    }

    static func prepareTableUserNetworkJoin(on connection: Database.Connection) -> Future<Void> {
        return Database.create(UserNetworkJoin.self, on: connection) { builder in
            builder.field(for: \UserNetworkJoin.id, isIdentifier: true)
            builder.field(for: \UserNetworkJoin.userId)
            builder.field(for: \UserNetworkJoin.networkId)
            builder.field(for: \UserNetworkJoin.created)
            builder.field(for: \UserNetworkJoin.updated)
            
            builder.unique(on: \UserNetworkJoin.userId, \UserNetworkJoin.networkId )
            
            // https://github.com/vapor/fluent/issues/538
            // generic models cannot set relational actions like Cascade or Nullify
            builder.reference(from: \UserNetworkJoin.userId, to: \User<Database>.id )
            builder.reference(from: \UserNetworkJoin.networkId, to: \Network<Database>.id)
        }
    }

    // MARK: - insert data
    static func prepareDefaultUserTypes(on connection: Database.Connection) -> [Future<Void>] {

        let futures : [EventLoopFuture<Void>] = sample_userTypes().map { usr in
            let code : String = usr["code"]!
            let display : String = usr["displayName"]!
            let defaultType : String? = usr["defaultType"]
            let newType = UserType<Database>(code: code, displayName: display)
            
            if defaultType != nil {
                newType.isDefaultType = true
            }
            return newType.create(on: connection).map(to: Void.self) { _ in return }
        }
        return futures
    }

    static func prepareDefaultNetworks(on connection: Database.Connection) -> [Future<Void>] {
        let futures : [EventLoopFuture<Void>] = sample_addresses().map { ipaddress in
            return Network<Database>(ip: ipaddress)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    // MARK: -
    public static func loadDefaultUsers(on connection: Database.Connection) -> [Future<Void>] {
        let futures : [EventLoopFuture<Void>] = sample_users().map { usr in
            let fname : String = usr["name"]!
            let uname : String = usr["username"]!
            let email : String = usr["email"]!
            let type : String = usr["type"]!
            let pword : String = usr["password"]!

            let user = User<Database>( name: fname, username: uname, email: email, type: type)
            user.password = pword
            return user
                .create(on: connection)
                .then { u -> Future<User<Database>> in
                    u.typeCode = type
                    return u.save(on: connection)
                }
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    public static func prepare(on connection: Database.Connection) -> Future<Void> {
        var allFutures : [EventLoopFuture<Void>] = [
            prepareTableUserType(on: connection),
            prepareTableNetwork(on: connection),
            prepareTableUser(on: connection),
            prepareTableUserNetworkJoin(on: connection)
        ]
        
        let insertUserTypes : [Future<Void>] = prepareDefaultUserTypes(on: connection)
        allFutures.append(contentsOf: insertUserTypes)

        let insertNetworks : [Future<Void>] = prepareDefaultNetworks(on: connection)
        allFutures.append(contentsOf: insertNetworks)

        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }
    
    public static func revert(on connection: Database.Connection) -> Future<Void> {
        let allFutures : [EventLoopFuture<Void>] = [
            Database.delete(UserNetworkJoin.self, on: connection),
            Database.delete(User.self, on: connection),
            Database.delete(Network.self, on: connection),
            Database.delete(UserType.self, on: connection),
        ]
        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }
}
