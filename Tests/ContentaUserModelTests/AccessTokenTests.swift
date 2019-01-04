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
        do {
            let file : ToolFile = try sqliteDataFile("\(#function)", "\(#file)")
            let conn = try openConnection(path: file)
            XCTAssertNotNil(conn)
            let connection = conn!
            defer {
                connection.close()
            }

            try assertTableExists( "access_token_type", connection )
            try assertTableExists( "access_token", connection )
            
            let apiType = try AccessTokenType<SQLiteDatabase>.forTokenCode(AccessTokenCode.API, on: connection)
            XCTAssertNotNil(apiType)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateAPITokens() {
        do {
            let file : ToolFile = try sqliteDataFile("\(#function)", "\(#file)")
            let conn = try openConnection(path: file)
            XCTAssertNotNil(conn)
            let connection = conn!
            addTeardownBlock({
                connection.close()
            })

            let apiType : AccessTokenType? = try AccessTokenType<SQLiteDatabase>.forTokenCode(AccessTokenCode.API, on: connection).wait()
            XCTAssertNotNil(apiType)

            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            for usr in users {
                let accessToken = try AccessToken(type: apiType!, user: usr).create(on: connection).wait()
                print( "\(usr.username) - \(accessToken.token) - \(accessToken.expires!)")
            }
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateAPITokenCodes() {
        do {
            let file : ToolFile = try sqliteDataFile("\(#function)", "\(#file)")
            let conn = try openConnection(path: file)
            XCTAssertNotNil(conn)
            let connection = conn!
            defer {
                connection.close()
            }

            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            for usr in users {
                let accessToken = try AccessToken.findOrCreateTokenCode( user: usr, andCode: AccessTokenCode.REMEMBER, on: connection).wait()
                print( "\(usr.username) - \(accessToken.token) - \(accessToken.expires!)")
            }
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testTokenQueries() {
        do {
            let file : ToolFile = try sqliteDataFile("\(#function)", "\(#file)")
            let conn = try openConnection(path: file)
            XCTAssertNotNil(conn)
            let connection = conn!
            defer {
                connection.close()
            }

            let apiType : AccessTokenType? = try AccessTokenType<SQLiteDatabase>.forTokenCode(AccessTokenCode.API, on: connection).wait()
            XCTAssertNotNil(apiType)

            let tokenTypes = try AccessTokenType<SQLiteDatabase>.query(on: connection).all().wait()
            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            for usr in users {
                for type in tokenTypes {
                    let accessToken = try AccessToken(type: type, user: usr).create(on: connection).wait()
                    print( "\(usr.username) - \(accessToken.token) - \(accessToken.expires!)")
                }
            }

            for usr in users {
                let userAPIToken = try usr.tokenFor(type: apiType!, on: connection).wait()
                XCTAssertNotNil(userAPIToken)
                XCTAssertFalse(userAPIToken!.isExpired)

                userAPIToken!.isExpired = true
                _ = userAPIToken!.save(on: connection)
            }

            let allTokens = try AccessToken<SQLiteDatabase>.query(on: connection).all().wait()
            let apiCode = try apiType!.requireID()
            for tok in allTokens {
                XCTAssertTrue( tok.isExpired || tok.typeCode != apiCode )
                let testFetch = try AccessToken<SQLiteDatabase>.forToken(tok.token, on: connection)
                XCTAssertNotNil(testFetch)
            }
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}

extension AccessTokenTests : DbTestCase {}
