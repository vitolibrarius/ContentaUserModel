//
//  PublicConvertable.swift
//

import Foundation
import Async
import Fluent

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
