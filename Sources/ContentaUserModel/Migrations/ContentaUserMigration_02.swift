// 

import Fluent
import ContentaTools
import Foundation

public struct ContentaUserMigration_02<D> : Migration where D: JoinSupporting & SchemaSupporting & MigrationSupporting {
    public typealias Database = D

    // MARK: - seed data
    static func sample_accessTokenTypes() -> [[String:Any]] {
        return [
            [ "code": AccessTokenCode.API.rawValue,      "displayName": "Machine Interface", "tokenExpirationInterval": 3600 ],
            [ "code": AccessTokenCode.REMEMBER.rawValue, "displayName": "Remember Me",       "tokenExpirationInterval": 3600 ],
            [ "code": AccessTokenCode.RESET.rawValue,    "displayName": "Password Reset",    "tokenExpirationInterval": 3600 ]
        ]
    }

    // MARK: - create tables
    static func prepareTableAccessTokenType(on connection: Database.Connection) -> Future<Void> {
        return Database.create(AccessTokenType.self, on: connection) { builder in
            
            //add fields
            builder.field(for: \AccessTokenType.code, isIdentifier: true)
            builder.field(for: \AccessTokenType.displayName)
            builder.field(for: \AccessTokenType.tokenExpirationInterval)
        }
    }

    static func prepareTableAccessToken(on connection: Database.Connection) -> Future<Void> {
        return Database.create(AccessToken.self, on: connection) { builder in
            
            //add fields
            builder.field(for: \AccessToken.id, isIdentifier: true)
            builder.field(for: \AccessToken.typeCode)
            builder.field(for: \AccessToken.userId)
            builder.field(for: \AccessToken.token)
            builder.field(for: \AccessToken.created)
            builder.field(for: \AccessToken.updated)
            builder.field(for: \AccessToken.expires)

            // https://github.com/vapor/fluent/issues/538
            // generic models cannot set relational actions like Cascade or Nullify
            builder.reference(from: \AccessToken.typeCode, to: \AccessTokenType<Database>.code)
            builder.reference(from: \AccessToken.userId, to: \User<Database>.id)

            // constraints
            builder.unique(on: \AccessToken.userId, \AccessToken.typeCode )
            builder.unique(on: \AccessToken.token )
        }
    }

    // MARK: - insert data
    static func prepareInsertAccessTokenTypes(on connection: Database.Connection) -> [Future<Void>] {

        let futures : [EventLoopFuture<Void>] = sample_accessTokenTypes().map { usr in
            let code : String = usr["code"]! as! String
            let display : String = usr["displayName"]! as! String
            let expValue : Int = usr["tokenExpirationInterval"]! as! Int
            let expires : TimeInterval = Double(expValue)
            return AccessTokenType<Database>(code: code, displayName: display, expires: expires)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }
        return futures
    }

    // MARK: -
    public static func prepare(on connection: Database.Connection) -> Future<Void> {
        var allFutures : [EventLoopFuture<Void>] = [
            prepareTableAccessTokenType(on: connection),
            prepareTableAccessToken(on: connection)
        ]
        
        let insertAccessTokenTypes : [Future<Void>] = prepareInsertAccessTokenTypes(on: connection)

        allFutures.append(contentsOf: insertAccessTokenTypes)

        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }
    
    public static func revert(on connection: Database.Connection) -> Future<Void> {
        let allFutures : [EventLoopFuture<Void>] = [
            Database.delete(AccessToken.self, on: connection),
            Database.delete(AccessTokenType.self, on: connection),
        ]
        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
    }
}
