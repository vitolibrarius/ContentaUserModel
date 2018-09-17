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

    public static var createdAtKey: TimestampKey? {
        return \Network.created
    }
    
    // MARK: - attributes
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

    public var isActive : Bool {
        get {
            return active
        }
        set {
            self.active = newValue
        }
    }
}

// MARK: - Relations
extension Network where D: JoinSupporting {
    public var userJoins: Siblings<Network, User<Database>, UserNetworkJoin<Database>> {
        return siblings()
    }
}

// MARK: queries
extension Network {
    public static func forIPAddress( _ ip : IPAddress, on connection: Database.Connection ) throws -> Network? {
        let matches = try Network.query(on: connection).filter(\Network.ipAddress == ip.address).all().wait()
        return matches.first
    }

    public static func findOrCreateIPAddress( _ ip : IPAddress, on connection: Database.Connection ) throws -> Network {
        let matches = try Network.query(on: connection).filter(\Network.ipAddress == ip.address).all().wait()
        if matches.count == 0 {
            return try Network(ip: ip).create(on: connection).wait()
        }
        return matches.first!
    }
}
