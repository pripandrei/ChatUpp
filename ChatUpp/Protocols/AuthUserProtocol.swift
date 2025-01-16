//
//  AuthUserProtocol.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/16/25.
//
import Foundation

protocol AuthUserProtocol {
    var authUser: AuthDataResultModel { get }
}

extension AuthUserProtocol
{
    var authUser: AuthDataResultModel {
        return try! AuthenticationManager.shared.getAuthenticatedUser()
    }
}
