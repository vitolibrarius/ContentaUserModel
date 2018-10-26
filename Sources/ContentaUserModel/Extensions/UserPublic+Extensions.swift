//
//  UserPublic+Extensions.swift
//

import Foundation
import Async
import Fluent
import Authentication

public protocol PublicConvertable {
    associatedtype PublicType
    func convertToPublic() -> PublicType?
}

extension Future where T: PublicConvertable {
    public func convertToPublic() -> Future<T.PublicType> {
        return self.map({ (item) -> T.PublicType in
            return item.convertToPublic()!
        })
    }
}

extension Optional : PublicConvertable where Wrapped: PublicConvertable {
    public typealias PublicType = Wrapped.PublicType

    public func convertToPublic() -> Wrapped.PublicType? {
        guard self != nil else {
            return nil
        }
        return self.unsafelyUnwrapped.convertToPublic()
    }
}

extension User : PublicConvertable {
    public typealias PublicType = User.Public
    
    public struct Public: Content, Codable {
        let id: User.ID
        let fullname: String
        let username: String
        let email: String
        let typeCode: String
    }

    public struct Register: Content, Codable {
        let fullname: String
        let username: String
        let email: String
        let password: String
    }
    
    public static func registerUser(_ register: Register, on connection: DatabaseConnectable ) throws -> Future<User<Database>> {
        return try User<Database>.forUsernameOrEmail(username: register.username, email: register.email, on: connection)
            .map { existingUsers in
                if existingUsers.count > 0 {
                    throw Abort(.badRequest)
                }
            }
            .then { t -> Future<User<Database>> in
                let user = User<Database>(name: register.fullname, username: register.username, email: register.email, type: "default")
                user.password = register.password
                return user.save(on: connection)
            }
    }

    public func convertToPublic() -> User<D>.Public? {
        return Public(
            id: self.id!,
            fullname: self.fullname,
            username: self.username,
            email: self.email,
            typeCode: self.typeCode
        )
    }
}

