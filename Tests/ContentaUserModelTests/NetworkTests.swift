//
//  NetworkTest.swift
//

import Foundation
import XCTest
import FluentSQLite
import ContentaTools

@testable import ContentaUserModel

final class NetworkTest: XCTestCase {
    static var allTests = [
        ("testNetworksUnique", testNetworksUnique),
        ]
    
    override func setUp() {
        super.setUp()
    }
    
    func testNetworksUnique() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            let conn = try openConnection(path: file)
            XCTAssertNotNil(conn)
            let connection = conn!
            defer {
                connection.close()
                defer {
                    do {
                        try file.delete()
                    }
                    catch  {
                        XCTFail(error.localizedDescription)
                    }
                }
            }

            let networks = try Network<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(networks.count, 2)
            
            // network.ipAddress is unique
            XCTAssertThrowsError(
                try Network<SQLiteDatabase>(ip: IPAddress("127.0.0.1")!).create(on: connection).wait()
            )
            
            XCTAssertNoThrow(
                try Network<SQLiteDatabase>(ip: IPAddress("192.168.1.1")!).create(on: connection).wait()
            )

            let networks2 = try Network<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(networks2.count, 3)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testNetworkJoinUnique() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            let conn = try openConnection(path: file)
            XCTAssertNotNil(conn)
            let connection = conn!
            defer {
                connection.close()
                defer {
                    do {
                        try file.delete()
                    }
                    catch  {
                        XCTFail(error.localizedDescription)
                    }
                }
            }

            let networks = try Network<SQLiteDatabase>.query(on: connection).all().wait()
            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()

            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(networks.count, 2)

            let ipaddress = IPAddress("127.0.0.1")!
            let nwork : Network<SQLiteDatabase>? = try Network<SQLiteDatabase>.forIPAddress(ipaddress, on: connection).wait()
            if nwork == nil {
                XCTFail()
            }

            let matches = try Network<SQLiteDatabase>.query(on: connection).filter(\Network<SQLiteDatabase>.ipAddress == ipaddress.address).all().wait()
            print(matches)
            for usr in users {
                for nwork in networks {
                    print( "\(nwork.ipAddress)")
                    _ = try usr.addNetworkIfAbsent(nwork, on: connection)
                }
            }

            for usr in users {
                let isAtt : Bool = try usr.isAttachedToAddress(IPAddress("127.0.0.1")!, on: connection).wait()
                print( "\(isAtt ? true :  false)")
            }

            
            // network.ipAddress is unique
            XCTAssertThrowsError(
                try Network<SQLiteDatabase>(ip: IPAddress("127.0.0.1")!).create(on: connection).wait()
            )
            
            XCTAssertNoThrow(
                try Network<SQLiteDatabase>(ip: IPAddress("192.168.1.1")!).create(on: connection).wait()
            )
            
            let networks2 = try Network<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(networks2.count, 3)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}

extension NetworkTest : DbTestCase {}


