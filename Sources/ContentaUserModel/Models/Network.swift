//
//  Network.swift
//

import Fluent
import Foundation
import ContentaTools

public final class Network<D>: Model where D: JoinSupporting {
    
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
}

// MARK: - Relations
//extension Network {
//    public var users: Siblings<Network, User<Database>, UserNetworkJoin<Database>> {
//        return siblings()
//    }
//}
