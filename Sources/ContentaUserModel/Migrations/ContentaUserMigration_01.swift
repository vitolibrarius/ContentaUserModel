// 

import Fluent
import ContentaTools
import Foundation

public struct ContentaUserMigration_01<D> : Migration where D: JoinSupporting & SchemaSupporting & MigrationSupporting {
    public typealias Database = D

    static func sample_userTypes() -> [[String:String]] {
        return [
            [ "code": "UNR",   "displayName": "Unregistered" ],
            [ "code": "REG",   "displayName": "Registered" ],
            [ "code": "ADMIN", "displayName": "Administrator" ]
        ]
    }

    static func sample_addresses() -> [IPAddress] {
        return [ IPAddress("127.0.0.1")!, IPAddress("fe80::1")! ]
    }

    static func sample_users() -> [[String:String]] {
        return [
            [ "username": "vito",     "type": "ADMIN", "email": "vitolibrarius@gmail.com" ],
            [ "username": "superman", "type": "REG",   "email": "clark.kent@gmail.com" ]
        ]
    }

    static func prepareTableUserType(on connection: Database.Connection) -> Future<Void> {
        return Database.create(UserType.self, on: connection) { builder in
            
            //add fields
            builder.field(for: \UserType.code, isIdentifier: true)
            builder.field(for: \UserType.displayName)
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
            builder.field(for: \User.email)
            builder.field(for: \User.active)
            builder.field(for: \User.created)
            builder.field(for: \User.updated)

            builder.reference(from: \User.typeCode, to: \UserType<Database>.code)
            
            // constraints
            builder.unique(on: \.email )
            builder.unique(on: \.username )
        }
    }

    static func prepareInsertUserTypes(on connection: Database.Connection) -> [Future<Void>] {

        let futures : [EventLoopFuture<Void>] = sample_userTypes().map { usr in
            let code : String = usr["code"]!
            let display : String = usr["displayName"]!
            return UserType<Database>(code: code, displayName: display)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    static func prepareInsertUsers(on connection: Database.Connection) -> [Future<Void>] {
        let futures : [EventLoopFuture<Void>] = sample_users().map { usr in
            let uname : String = usr["username"]!
            let email : String = usr["email"]!
            let type : String = usr["type"]!
            return User<Database>(username: uname, email: email, type: type)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    static func prepareInsertNetworks(on connection: Database.Connection) -> [Future<Void>] {
        let futures : [EventLoopFuture<Void>] = sample_addresses().map { ipaddress in
            return Network<Database>(ip: ipaddress)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    public static func prepare(on connection: Database.Connection) -> Future<Void> {
        
        let createUserType : Future<Void> = prepareTableUserType(on: connection)
        let createNetwork : Future<Void> = prepareTableNetwork(on: connection)
        let createUser : Future<Void> = prepareTableUser(on: connection)
        //        let futureCreateIndexes = prepareIndexes(on: connection)
        let insertUserTypes : [Future<Void>] = prepareInsertUserTypes(on: connection)
        let insertUsers : [Future<Void>] = prepareInsertUsers(on: connection)
        let insertNetworks : [Future<Void>] = prepareInsertNetworks(on: connection)

        var allFutures : [EventLoopFuture<Void>] = []
        allFutures.append(createUserType)
        allFutures.append(createNetwork)
        allFutures.append(createUser)
        allFutures.append(contentsOf: insertUserTypes)
        allFutures.append(contentsOf: insertUsers)
        allFutures.append(contentsOf: insertNetworks)

        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }
    
    public static func revert(on connection: Database.Connection) -> Future<Void> {
        return Database.delete(User.self, on: connection)
    }
}
