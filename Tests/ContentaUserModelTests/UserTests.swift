//
//  UserTest.swift
//

import Foundation
import XCTest
import FluentSQLite
import ContentaTools

@testable import ContentaUserModel

final class UserTests: XCTestCase {
    static var allTests = [
        ("testMigration", testMigration),
        ("testUnique", testUnique),
        ("testPasswords", testPasswords),
        ("testDeletes", testDeletes)
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

            try assertTableExists( "user", conn )
            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()
            let networks = try Network<SQLiteDatabase>.query(on: conn).all().wait()
            for nwork in networks {
                nwork.isActive = false
                _ = nwork.update(on: conn)
            }
            
            for usr in users {
                for ip in [IPAddress("192.168.1.1")!, IPAddress("192.168.1.2")!, IPAddress("192.168.1.3")! ] {
                    let nwork : Network<SQLiteDatabase> = try usr.addAddressIfAbsent(ip, on: conn)
                    print( "\(ip.address) .. \(nwork.ipHash)")
                }
            }

            for usr in users {
                let ut = try usr.type.get(on: conn).wait()
                let nworks = try usr.networkJoins.query(on: conn).all().wait()
                print( "\(ut.displayName):\t \(usr.username) -> \(usr.created!)")
                for n in nworks {
                    print( "\t\(n.ipHash)")
                }
            }
//            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testUnique() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            
            try assertTableExists( "user", conn )
            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(users.count, 2)
            
            // username and email are both unique
            //             [ "username": "vito",     "type": "ADMIN", "email": "vitolibrarius@gmail.com" ],

            XCTAssertThrowsError(
                try User<SQLiteDatabase>(name: "test assert", username: "vito", email: "none@whatever", type: "ADMIN" ).create(on: conn).wait()
            )

            XCTAssertThrowsError(
                try User<SQLiteDatabase>(name: "test assert", username: "someone", email: "vitolibrarius@gmail.com", type: "ADMIN" ).create(on: conn).wait()
            )

            XCTAssertNoThrow(
                try User<SQLiteDatabase>(name: "test assert", username: "someone", email: "anyone@gmail.com", type: "ADMIN" ).create(on: conn).wait()
            )

            let users2 = try User<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(users2.count, 3)

            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testPasswords() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            
            try assertTableExists( "user", conn )
            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(users.count, 2)
            
            guard let vito: User<SQLiteDatabase> = try User<SQLiteDatabase>.forUsername("vito", on: conn) else {
                XCTFail()
                return
            }
            
            //XCTAssertNil(try vito.changePassword("", on: conn))
            XCTAssertTrue(try vito.passwordVerify("TeSt12345"))
            XCTAssertFalse(try vito.passwordVerify("C0nt3nta"))

            _ = try vito.changePassword("C0nt3nta", on: conn).wait()
            XCTAssertFalse(try vito.passwordVerify("TeSt12345"))
            XCTAssertTrue(try vito.passwordVerify("C0nt3nta"))
            
            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeletes() {
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

            try assertTableExists( "user", conn )
            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(users.count, 2)
            
            guard let vito: User<SQLiteDatabase> = try User<SQLiteDatabase>.forUsername("vito", on: conn) else {
                XCTFail()
                return
            }

            let ipaddress = IPAddress("127.0.0.1")!
            let nwork = try Network<SQLiteDatabase>.forIPAddress(ipaddress, on: conn)
            XCTAssertNotNil(nwork)
            _ = try vito.addNetworkIfAbsent(nwork!, on: conn)

            let apiType : AccessTokenType = try AccessTokenType<SQLiteDatabase>.forCode("API", on: conn)!
            XCTAssertNotNil(apiType)
            let token = try vito.findOrCreateToken(type: apiType, on: conn)
            XCTAssertNotNil(token)

            // delete vito
            _ = try vito.delete(on: conn).wait()

//            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}

extension UserTests : DbTestCase {}

