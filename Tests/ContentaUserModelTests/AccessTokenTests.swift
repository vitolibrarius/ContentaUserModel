//
//  AccessTokenTests.swift
//

import Foundation
import XCTest
import FluentSQLite
import ContentaTools

@testable import ContentaUserModel

final class AccessTokenTests: XCTestCase {

    static var allTests = [
        ("testMigration", testMigration),
        ("testCreateAPITokens", testCreateAPITokens),
        ("testTokenQueries", testTokenQueries)
    ]

    override func setUp() {
        super.setUp()
    }
    
    func testMigration() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            try ContentaUserMigration_02<SQLiteDatabase>.prepare(on: conn).wait()

            try assertTableExists( "access_token_type", conn )
            try assertTableExists( "access_token", conn )
            
            let apiType = try AccessTokenType<SQLiteDatabase>.forCode("API", on: conn)
            XCTAssertNotNil(apiType)
            
            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateAPITokens() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            try ContentaUserMigration_02<SQLiteDatabase>.prepare(on: conn).wait()
            
            try assertTableExists( "access_token_type", conn )
            try assertTableExists( "access_token", conn )

            let apiType : AccessTokenType? = try AccessTokenType<SQLiteDatabase>.forCode("API", on: conn).wait()
            XCTAssertNotNil(apiType)

            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()
            for usr in users {
                let accessToken = try AccessToken(type: apiType!, user: usr).create(on: conn).wait()
                print( "\(usr.username) - \(accessToken.token) - \(accessToken.expires!)")
            }

            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testTokenQueries() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            try ContentaUserMigration_02<SQLiteDatabase>.prepare(on: conn).wait()
            
            try assertTableExists( "access_token_type", conn )
            try assertTableExists( "access_token", conn )

            let apiType : AccessTokenType? = try AccessTokenType<SQLiteDatabase>.forCode("API", on: conn).wait()
            XCTAssertNotNil(apiType)

            let tokenTypes = try AccessTokenType<SQLiteDatabase>.query(on: conn).all().wait()
            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()
            for usr in users {
                for type in tokenTypes {
                    let accessToken = try AccessToken(type: type, user: usr).create(on: conn).wait()
                    print( "\(usr.username) - \(accessToken.token) - \(accessToken.expires!)")
                }
            }

            for usr in users {
                let userAPIToken = try usr.tokenFor(type: apiType!, on: conn).wait()
                XCTAssertNotNil(userAPIToken)
                XCTAssertFalse(userAPIToken!.isExpired)

                userAPIToken!.isExpired = true
                _ = userAPIToken!.save(on: conn)
            }

            let allTokens = try AccessToken<SQLiteDatabase>.query(on: conn).all().wait()
            let apiCode = try apiType!.requireID()
            for tok in allTokens {
                XCTAssertTrue( tok.isExpired || tok.typeCode != apiCode )
                let testFetch = try AccessToken<SQLiteDatabase>.forToken(tok.token, on: conn)
                XCTAssertNotNil(testFetch)
            }
            
            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}

extension AccessTokenTests : DbTestCase {}
