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
                print( "\(nwork.ipAddress)")
                //                    usr.networks.attach(nwork, on: conn).wait()
            }

            for usr in users {
                let ut = try usr.type.get(on: conn).wait()
                print( "\(ut.displayName):\t \(usr.username) -> \(usr.created!)")
            }
            print("\(users)")
            //try file.delete()
        }
        catch  {
            XCTAssertTrue(false, error.localizedDescription)
        }
    }
}

extension UserTests : DbTestCase {}

