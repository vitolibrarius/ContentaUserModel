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
    public func convertToPublic() -> Future<T.PublicType?> {
        return self.map({ (item) -> T.PublicType? in
            return item.convertToPublic() ?? nil
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

