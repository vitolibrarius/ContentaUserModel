//
//  UserNetworkJoin.swift
//

import Async
import Fluent
import Foundation

public final class UserNetworkJoin<D>: ModifiablePivot where D: JoinSupporting {
    // MARK: ID
    public typealias Database = D
    public typealias ID = Int

    public typealias Left = User<D>
    public typealias Right = Network<D>

    public static var idKey: IDKey { return \.id }
    public static var leftIDKey: LeftIDKey {
        return \UserNetworkJoin.userId
    }
    public static var rightIDKey: RightIDKey {
        return \UserNetworkJoin.networkId
    }
    public static var createdAtKey: TimestampKey? {
        return \UserNetworkJoin.created
    }
    public static var updatedAtKey: TimestampKey? {
        return \UserNetworkJoin.updated
    }

    public static var entity: String {
        return "user_network"
    }
    
    // MARK: - attributes
    public var id: ID?
    public var userId: Int
    public var networkId: Int
    public var created: Date?
    public var updated: Date?

    public init(_ user: User<Database>, _ network: Network<Database>) throws {
        userId = try user.requireID()
        networkId = try network.requireID()
    }
}

