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
//    let photoURL: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
    }
}

final class AuthenticationManager {
    
    static var shared = AuthenticationManager()
    
    private init() {}
    
    func createUser(email: String, password: String, complition: @escaping ((authDataResultModel?) -> Void))   {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("There was an error creating a user")
                complition(nil)
                return
            }
            let authDataResultModel = authDataResultModel(user: result.user)
            complition(authDataResultModel)
        }
    }
}
