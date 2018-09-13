//
//  UserMigration_01.swift
//

import Fluent
import Foundation

let sample_users: [[String:String]] = [
    [
        "username": "vito",
        "email": "vitolibrarius@gmail.com"
    ]
]

struct UserMigration_01<D> : Migration where D: QuerySupporting & SchemaSupporting & MigrationSupporting {
    typealias Database = D
    
    
    static func prepareFields(on connection: Database.Connection) -> Future<Void> {
        return Database.create(User.self, on: connection) { builder in

            //add fields
            builder.field(for: \User.id)
            builder.field(for: \User.username)
            builder.field(for: \User.email)
            builder.field(for: \User.active)
            builder.field(for: \User.created)

//            //indexes
//            builder.addIndex(to: \.username, isUnique: false)
//            builder.addIndex(to: \.email, isUnique: true)
        }
    }

//    static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
//        let futures : [EventLoopFuture<Void>] = sample_users.map { usr in
//            return User(username: usr["username"]!, email:usr["email"]!)
//                .create(on: connection)
//                .map(to: Void.self) { _ in return }
//        }
//        return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
//    }

    public static func prepare(on connection: Database.Connection) -> Future<Void> {

        let futureCreateFields = prepareFields(on: connection)
//        let futureInsertData = prepareInsertData(on: connection)

        let allFutures : [EventLoopFuture<Void>] = [futureCreateFields] //, futureInsertData]

        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }

    public static func revert(on connection: Database.Connection) -> Future<Void> {
        return Database.delete(User.self, on: connection)
    }
}
