//
//  Network.swift
//

import Fluent
import Foundation
import ContentaTools

public final class Network<D>: Model where D: QuerySupporting {
    
    // MARK: ID
    public typealias Database = D
    public typealias ID = Int
    
    public static var idKey: IDKey { return \.id }
    public static var entity: String {
        return "network"
    }
    public static var database: DatabaseIdentifier<D> {
        return .init("networks")
    }

    public static var createdAtKey: TimestampKey { return \.created }
    
    var id: Int?
    
    var ipAddress: String
    var ipHash: String
    var active: Bool = true
    var created: Date?
    
    /// Creates a new `Network`.
    init( ip: IPAddress ) {
        self.ipAddress = ip.address
        self.ipHash = ip.normalized
    }
}

//let sample_addresses: [IPAddress] = [
//    IPAddress("127.0.0.1")!,
//    IPAddress("fe80::1")!
//]
//
//// MARK: - NetworkMigration
//public struct NetworkMigration<D>: Migration where D: QuerySupporting & SchemaSupporting {
//    public typealias Database = D
//    
//    static func prepareFields(on connection: Database.Connection) -> Future<Void> {
//        return Database.create(Network<Database>.self, on: connection) { builder in
//            
//            //add fields
//            try builder.field(for: \Network<Database>.id)
//            try builder.field(for: \Network<Database>.ipHash)
//            try builder.field(for: \Network<Database>.ipAddress)
//            try builder.field(for: \Network<Database>.active)
//            try builder.field(for: \Network<Database>.created)
//
//            //indexes
//            try builder.addIndex(to: \.ipHash, isUnique: true)
//        }
//    }
//    
//    static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
//        let futures : [EventLoopFuture<Void>] = sample_addresses.map { address in
//            return Network<D>(ip: address).create(on: connection).map(to: Void.self) { _ in return }
//        }
//        return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
//    }
//    
//    public static func prepare(on connection: Database.Connection) -> Future<Void> {
//        
//        let futureCreateFields = prepareFields(on: connection)
//        let futureInsertData = prepareInsertData(on: connection)
//        
//        let allFutures : [EventLoopFuture<Void>] = [futureCreateFields, futureInsertData]
//        
//        return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
//    }
//    
//    public static func revert(on connection: Database.Connection) -> Future<Void> {
//        do {
//            // Delete all sample_addresses
//            let futures = try sample_addresses.map { address -> EventLoopFuture<Void> in
//                return try Network<D>.query(on: connection).filter(\Network.ipAddress, .equals, .data(address.address)).delete()
//            }
//            return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
//        }
//        catch {
//            return connection.eventLoop.newFailedFuture(error: error)
//        }
//    }
//}
