//
//  UserMigration_01.swift
//

import Fluent
import Foundation

let sample_users: [[String:String]] = [
    [
        "username": "vito",
        "email": "vitolibrarius@gmail.com"
    ],
    [
        "username": "superman",
        "email": "clark.kent@gmail.com"
    ]
]

struct UserMigration_01<D> : Migration where D: QuerySupporting & SchemaSupporting & MigrationSupporting {
    typealias Database = D
    typealias Constraint = D.SchemaConstraint
    
    static func prepareFields(on connection: Database.Connection) -> Future<Void> {
        return Database.create(User.self, on: connection) { builder in

            //add fields
            builder.field(for: \User.id, isIdentifier: true)
            builder.field(for: \User.username)
            builder.field(for: \User.email)
            builder.field(for: \User.active)
            builder.field(for: \User.created)

            //    builder.foreignKey("user_id", references: "id", on: User.self)

            // constraints
            builder.unique(on: \.email )
            builder.unique(on: \.username )
        }
    }
    
//    static func prepareIndexes(on connection: Database.Connection) -> Future<Void> {
//        //CREATE UNIQUE INDEX IF NOT EXISTS artist_alias_artist__02 on artist_alias (artist_id,name COLLATE NOCASE);
//
//        //let entityName : String = User.entity
//        return User<Database>.query(on: connection).filter(\User.active).delete()
////User.query(on: connection)
////            connection.query("create index IF NOT EXISTS \(User.entity())_\(\User.created) on  ")
//
//    }

    static func prepareInsertData(on connection: Database.Connection) -> [Future<Void>] {
        let futures : [EventLoopFuture<Void>] = sample_users.map { usr in
            let uname : String = usr["username"]!
            let email : String = usr["email"]!
            return User<Database>(username: uname, email: email)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    public static func prepare(on connection: Database.Connection) -> Future<Void> {

        let futureCreateFields : Future<Void> = prepareFields(on: connection)
//        let futureCreateIndexes = prepareIndexes(on: connection)
        let futureInsertData : [Future<Void>] = prepareInsertData(on: connection)

        var allFutures : [EventLoopFuture<Void>] = []
        allFutures.append(futureCreateFields)
        allFutures.append(contentsOf: futureInsertData)

        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }

    public static func revert(on connection: Database.Connection) -> Future<Void> {
        return Database.delete(User.self, on: connection)
    }
}
