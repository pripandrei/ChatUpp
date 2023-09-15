//
//  UserManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/16/23.
//

import Foundation
import FirebaseFirestore

final class UserManager {
    
    static let shared = UserManager()
    
    private init() {}
    
    func createNewUser(with authData: authDataResultModel, _ complition: @escaping (Bool) -> Void) {
        
        var userData: [String: Any] = [
            "user_id" : authData.uid,
            "date_created" : Timestamp(),
        ]
        
        if let email = authData.email {
            userData["email"] = email
        }
        if let photoURL = authData.photoURL {
            userData["photo_url"] = photoURL
        }
        
        Firestore.firestore().collection("users").document(authData.uid).setData(userData) { error in
            if let error = error {
                print("Error creating user document: \(error.localizedDescription)")
                complition(false)
            }
            complition(true)
        }
    }
    
    
}
