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
        ("testDeletes", testDeletes),
        ("testDecoding", testDecoding)
    ]
    
    override func setUp() {
        super.setUp()
    }

    func testMigration() {
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

            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            let networks = try Network<SQLiteDatabase>.query(on: connection).all().wait()
            for nwork in networks {
                nwork.isActive = false
                _ = nwork.update(on: connection)
            }
            
            for usr in users {
                for ip in [IPAddress("192.168.1.1")!, IPAddress("192.168.1.2")!, IPAddress("192.168.1.3")! ] {
                    let nwork : Network<SQLiteDatabase> = try usr.addAddressIfAbsent(ip, on: connection).wait()
                    print( "\(ip.address) .. \(nwork.ipHash)")
                }
            }

            for usr in users {
                let ut = try usr.type.get(on: connection).wait()
                let nworks = try usr.networks.query(on: connection).all().wait()
                print( "\(ut.displayName):\t \(usr.username) -> \(usr.created!)")
                if usr.username == "vitolib" {
                    XCTAssertEqual(usr.typeCode, "ADMIN")
                }
                for n in nworks {
                    print( "\t\(n.ipHash)")
                }
            }
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testUnique() {
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

            // username and email are both unique
            //             [ "username": "vito",     "type": "ADMIN", "email": "vitolibrarius@gmail.com" ],

            XCTAssertThrowsError(
                try User<SQLiteDatabase>(name: "test assert", username: "vito", email: "none@whatever", type: "ADMIN" ).create(on: connection).wait()
            )

            XCTAssertThrowsError(
                try User<SQLiteDatabase>(name: "test assert", username: "someone", email: "vitolibrarius@gmail.com", type: "ADMIN" ).create(on: connection).wait()
            )

            XCTAssertNoThrow(
                try User<SQLiteDatabase>(name: "test assert", username: "someone", email: "anyone@gmail.com", type: "ADMIN" ).create(on: connection).wait()
            )

            let users2 = try User<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(users2.count, 3)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testPasswords() {
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

            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(users.count, 2)
            
            let vito: User<SQLiteDatabase>? = try User<SQLiteDatabase>.forUsername("vitolib", on: connection).wait()
            if vito == nil {
                XCTFail()
            }
            
            //XCTAssertNil(try vito.changePassword("", on: connection))
            XCTAssertTrue(try vito!.passwordVerify("TeSt12345"))
            XCTAssertFalse(try vito!.passwordVerify("C0nt3nta"))

            _ = try vito!.changePassword("C0nt3nta", on: connection).wait()
            XCTAssertFalse(try vito!.passwordVerify("TeSt12345"))
            XCTAssertTrue(try vito!.passwordVerify("C0nt3nta"))
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeletes() {
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

            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(users.count, 2)
            
            let vito: User<SQLiteDatabase>? = try User<SQLiteDatabase>.forUsername("vitolib", on: connection).wait()
            XCTAssertNotNil(vito)

            let ipaddress = IPAddress("127.0.0.1")!
            let nwork = try Network<SQLiteDatabase>.forIPAddress(ipaddress, on: connection).wait()
            XCTAssertNotNil(nwork)
            _ = try vito!.addNetworkIfAbsent(nwork!, on: connection)

            let apiType = try AccessTokenType<SQLiteDatabase>.forCode("API", on: connection).wait()
            XCTAssertNotNil(apiType)
            let token = try vito!.findOrCreateToken(type: apiType!, on: connection).wait()
            XCTAssertNotNil(token)

            // delete vito, should also cascade to owned objects
            _ = try vito!.delete(on: connection).wait()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testPublic() {
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

            let vito = try User<SQLiteDatabase>.forUsername("vitolib", on: connection).wait()
            XCTAssertNotNil(vito)
            
            let vitoPub = vito!.convertToPublic()
            XCTAssertNotNil(vitoPub)
            XCTAssertEqual(try vito!.requireID(), vitoPub!.id)

            // test Future<User> convert Future<User.Public>
            let futureSuperman: Future<User<SQLiteDatabase>?> = try User<SQLiteDatabase>.forUsername("superman", on: connection)
            let x = futureSuperman.convertToPublic()
            let publicSuperman = try x.wait()
            let superman: User<SQLiteDatabase>? = try futureSuperman.wait()
            XCTAssertNotEqual(try vito!.requireID(), publicSuperman.id)
            XCTAssertEqual(try superman!.requireID(), publicSuperman.id)
            
            let allUsersQuery = User<SQLiteDatabase>.query(on: connection)
            let queryDecode  = allUsersQuery.decode(data: User<SQLiteDatabase>.Public.self)
            let futureAll = queryDecode.all()
            let allPublic = try futureAll.wait()
            print("\(allPublic)")
                //.decode(User<SQLiteDatabase>.Public.self).all()
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testQueries() {
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

            let vito: User<SQLiteDatabase>? = try User<SQLiteDatabase>.forUsername("vitolib", on: connection).wait()
            if vito == nil {
                XCTFail()
            }

            let also_vito: User<SQLiteDatabase>? = try User<SQLiteDatabase>.forEmail("vitolibrarius@gmail.com", on: connection).wait()
            if also_vito == nil {
                XCTFail()
            }

            let not_vito: User<SQLiteDatabase>? = try User<SQLiteDatabase>.forEmail("joe@gmail.com", on: connection).wait()
            if not_vito != nil {
                XCTFail()
            }

            let vitoAndSuperman = try User<SQLiteDatabase>.forUsernameOrEmail(username: "superman", email: "vitolibrarius@gmail.com", on: connection).wait()
            XCTAssertEqual(vitoAndSuperman.count, 2)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecoding() {
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

            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(users.count, 2)
            
            let json = """
{
    "fullname" : "Sally Simpson",
    "username" : "sallys",
    "email" : "sally@gmail.com",
    "typeCode": "REG",
    "passwordHash": "Test23456"
}
"""
            let data = Data(json.utf8)
            let decoder = JSONDecoder()
            let user = try! decoder.decode(User<SQLiteDatabase>.self, from: data)
            user.password = user.passwordHash ?? "locked out"
            _ = try user.save(on: connection).wait()

            print( "\(user)" )
            let id = user.id ?? 0
            print( "\(user.username) \(id) = \(user.password)" )
            XCTAssertTrue( try user.passwordVerify("Test23456") )
            
            let newUser = try User<SQLiteDatabase>.find(user.requireID(), on: connection).wait()
            XCTAssertEqual(newUser?.email, user.email)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }

    func testRegisterDecoding() {
        let decoder = JSONDecoder()

        let goodJson = """
{
    "fullname" : "Sally Simpson",
    "username" : "good-decoded",
    "email" : "sally@gmail.com",
    "password": "Test23456"
}
"""
        let goodData = Data(goodJson.utf8)
        let goodRegister = try! decoder.decode(User<SQLiteDatabase>.Register.self, from: goodData)
        XCTAssertEqual(goodRegister.username, "good-decoded")

        let badJson = """
{
    "fullname" : "Sally Simpson",
    "username" : "missing-password",
    "email" : "sally@gmail.com",
}
"""
        let badData = Data(badJson.utf8)
        XCTAssertThrowsError(try decoder.decode(User<SQLiteDatabase>.Register.self, from: badData))
    }

    func testRegister() {
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
            
            let users = try User<SQLiteDatabase>.query(on: connection).all().wait()
            XCTAssertEqual(users.count, 2)
            let DefaultUserType = try UserType<SQLiteDatabase>.defaultTypeCode(on: connection).wait()!

            let json = """
{
    "fullname" : "Sally Simpson",
    "username" : "sallys",
    "email" : "sally@gmail.com",
    "password": "Test23456"
}
"""
            let data = Data(json.utf8)
            let decoder = JSONDecoder()
            let register = try! decoder.decode(User<SQLiteDatabase>.Register.self, from: data)
            XCTAssertEqual(register.username, "sallys")
            let user = try User<SQLiteDatabase>.registerUser(register, on: connection).wait()

            let ut = try user.type.get(on: connection).wait()
            let id = user.id ?? 0
            print( "\(ut.displayName) #\(id): \(user.username) | \(user.password)" )
            XCTAssertEqual(DefaultUserType, ut)
            XCTAssertTrue( try user.passwordVerify("Test23456") )
            XCTAssertFalse( try user.passwordVerify("Smoke23456") )

            let newUser = try User<SQLiteDatabase>.find(user.requireID(), on: connection).wait()
            XCTAssertEqual(newUser?.email, user.email)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}

extension UserTests : DbTestCase {}

