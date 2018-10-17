//
//  DbTestCase.swift
//

import Foundation
import Fluent
import FluentSQLite
import ContentaTools
import XCTest

@testable import ContentaUserModel

protocol DbTestCase {}

extension DbTestCase {

    func openConnection(path filename: ToolFile ) throws -> SQLiteConnection? {
        XCTAssertNotNil(filename)
        if ( filename.exists ) {
            try filename.delete()
        }

        do {
            let sqlite = try SQLiteDatabase(storage: .file(path: filename.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let connection = try sqlite.newConnection(on: eventLoop).wait()
            try SQLiteDatabase.enableReferences(on: connection).wait()

            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: connection).wait()
            try ContentaUserMigration_02<SQLiteDatabase>.prepare(on: connection).wait()

            try assertTableExists( User<SQLiteDatabase>.entity, connection )
            try assertTableExists( Network<SQLiteDatabase>.entity, connection )
            try assertTableExists( AccessToken<SQLiteDatabase>.entity, connection )
            
            return connection
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
        return nil
    }

    func sqliteDataFile(_ testName: String, _ testClassName: String) -> ToolFile {
        let test = testName.removeCharacterSet(from: CharacterSet.alphanumerics.inverted)
        let lastpath = (testClassName as NSString).lastPathComponent
        let filename = (lastpath as NSString).deletingPathExtension
        let file : ToolFile = (ToolDirectory.systemTmp.subItem(filename + "_" + test + ".sqlite", type: FSItemType.FILE) as! ToolFile)
        return file
    }
    
    func assertTableExists(_ tableName: String, _ connection: SQLiteConnection ) throws {
        XCTAssertTrue(tableName.count > 0, "Table name is empty")
        let tables : [[SQLiteColumn : SQLiteData]] = try connection.query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").wait()
        let tableNames : [String] = try tables.map({ (row) -> String in
            let val : [String] = try row.map({
                let str = try String.convertFromSQLiteData($0.value)
                return str
            })
            return val[0]
        })
        XCTAssertTrue(tableNames.contains(tableName))
    }
}
