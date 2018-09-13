//
//  DbTestCase.swift
//

import Foundation
import Fluent
import FluentSQLite
import ContentaTools
import XCTest

protocol DbTestCase {}

extension DbTestCase {

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
