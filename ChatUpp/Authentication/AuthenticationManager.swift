//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/5/23.
//

import Foundation
import FirebaseAuth

struct authDataResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
    }
}

final class AuthenticationManager {
    
    static var shared = AuthenticationManager()
    
    private init() {}
    
    func getAuthenticatedUser() throws -> authDataResultModel {
        if let user = Auth.auth().currentUser {
            return authDataResultModel(user: user)
        }
        throw URLError(.badServerResponse)
    }
    
    func signIn(email: String, password: String, complition: @escaping (authDataResultModel?) -> Void)  {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("Could not log you in. Error: \(String(describing: error))")
                complition(nil)
                return
            }
            let authDataResultModel = authDataResultModel(user: result.user)
            complition(authDataResultModel)
        }
    }
    
    func signUpUser(email: String, password: String, complition: @escaping ((authDataResultModel?) -> Void))  {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("There was an error during user registration: \(error?.localizedDescription)")
                complition(nil)
                return
            }
            let authDataResultModel = authDataResultModel(user: result.user)
            complition(authDataResultModel)
        }
    }
}
