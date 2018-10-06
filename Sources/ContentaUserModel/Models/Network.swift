//
//  Network.swift
//

import Fluent
import Foundation
import ContentaTools
import Vapor
import Validation

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
    var id: ID?
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
    public static func forIPAddress( _ ip : IPAddress, on connection: Database.Connection ) throws -> Future<Network?> {
        return Future.flatMap(on: connection) {
            return Network.query(on: connection).filter(\Network.ipAddress == ip.address).first().map { tok in
                return tok ?? nil
            }
        }
    }

    public static func findOrCreateIPAddress( _ ip : IPAddress, on connection: Database.Connection ) throws -> Future<Network> {
        return try Network<Database>.forIPAddress( ip, on: connection ).flatMap { nwork in
            guard let network = nwork else {
                return Network(ip: ip).create(on: connection)
            }
            return Future.map(on: connection) { network }
        }
    }
}

// MARK: - Content - Parameter
extension Network: Content {}
extension Network: Parameter {}
