//
//  AuthUserProtocol.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//
import Foundation

protocol AuthUserProtocol {
    var authUser: AuthenticatedUserData { get }
}

extension AuthUserProtocol
{
    var authUser: AuthenticatedUserData {
        return try! AuthenticationManager.shared.getAuthenticatedUser()
    }
}
