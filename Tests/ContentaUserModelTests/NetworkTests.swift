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
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            
            try assertTableExists( "network", conn )
            let networks = try Network<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(networks.count, 2)
            
            // network.ipAddress is unique
            XCTAssertThrowsError(
                try Network<SQLiteDatabase>(ip: IPAddress("127.0.0.1")!).create(on: conn).wait()
            )
            
            XCTAssertNoThrow(
                try Network<SQLiteDatabase>(ip: IPAddress("192.168.1.1")!).create(on: conn).wait()
            )

            let networks2 = try Network<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(networks2.count, 3)

            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testNetworkJoinUnique() {
        let file : ToolFile = sqliteDataFile("\(#function)", "\(#file)")
        do {
            if ( file.exists ) {
                try file.delete()
            }
            
            let sqlite = try SQLiteDatabase(storage: .file(path: file.fullPath))
            let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            let conn = try sqlite.newConnection(on: eventLoop).wait()
            
            try ContentaUserMigration_01<SQLiteDatabase>.prepare(on: conn).wait()
            
            try assertTableExists( "network", conn )
            try assertTableExists( "user", conn )
            let networks = try Network<SQLiteDatabase>.query(on: conn).all().wait()
            let users = try User<SQLiteDatabase>.query(on: conn).all().wait()

            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(networks.count, 2)

            let ipaddress = IPAddress("127.0.0.1")!
            let nwork = try Network<SQLiteDatabase>.forIPAddress(ipaddress, on: conn)
            if nwork != nil {
                print("Found it \(nwork!.ipHash)")
            }
            let matches = try Network<SQLiteDatabase>.query(on: conn).filter(\Network<SQLiteDatabase>.ipAddress == ipaddress.address).all().wait()
            print(matches)
            for usr in users {
                for nwork in networks {
                    print( "\(nwork.ipAddress)")
                    _ = try usr.addNetworkIfAbsent(nwork, on: conn)
                }
            }

            for usr in users {
                let isAtt : Bool = try usr.isAttachedToAddress(IPAddress("127.0.0.1")!, on: conn)
                print( "\(isAtt ? true :  false)")
            }

            
            // network.ipAddress is unique
            XCTAssertThrowsError(
                try Network<SQLiteDatabase>(ip: IPAddress("127.0.0.1")!).create(on: conn).wait()
            )
            
            XCTAssertNoThrow(
                try Network<SQLiteDatabase>(ip: IPAddress("192.168.1.1")!).create(on: conn).wait()
            )
            
            let networks2 = try Network<SQLiteDatabase>.query(on: conn).all().wait()
            XCTAssertEqual(networks2.count, 3)
            
            try file.delete()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}

extension NetworkTest : DbTestCase {}


