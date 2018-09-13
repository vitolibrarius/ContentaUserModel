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

            try UserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()

            try assertTableExists( "user", conn )
            try file.delete()
        }
        catch  {
            XCTAssertTrue(false, error.localizedDescription)
        }
    }
}

extension UserTests : DbTestCase {}

