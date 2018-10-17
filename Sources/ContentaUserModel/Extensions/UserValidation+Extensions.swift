//
//  UserValidation+Extensions.swift
//

import Foundation
import Async
import Fluent
import Authentication

// MARK: - validation
extension User : Validatable, Reflectable {
    public func changePassword(_ password: String, on connection: Database.Connection ) throws -> EventLoopFuture<User> {
        // validate
        try Validator<String>.password.validate(password)
        
        self.passwordHash = try BCrypt.hash(password) // 12 iterations, random salt
        return self.save(on: connection)
    }
    
    public func passwordVerify(_ password: String) throws -> Bool {
        if self.passwordHash == nil {
            return false
        }
        return try BCrypt.verify(password, created: self.passwordHash!)
    }

    public static func validations() throws -> Validations<User<D>> {
        var validations = Validations(User.self)
        try validations.add( \User.username, Validator<String>.alphanumeric)
        try validations.add( \User.username, Validator<String>.count(5...))
        try validations.add( \User.email, Validator<String>.email)
        return validations
    }
}
