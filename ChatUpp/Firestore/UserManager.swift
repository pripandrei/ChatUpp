//
//  UserManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/16/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser {
    let uid: String
//    let name: String
    let date: Date?
    let email: String?
    let photoURL: String?
}

final class UserManager {
    
    static let shared = UserManager()
    
    private init() {}
    
    func updateUser(with userID: String, usingName name: String, complition: @escaping (ResposneStatus) -> Void) {
        let userData: [String: Any] = [
            "name" : name
        ]
        Firestore.firestore().collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                print("There was an error updating username: ", error.localizedDescription)
                complition(.failed)
                return
            }
            complition(.success)
        }
    }
    
    func createNewUser(with authData: AuthDataResultModel, _ complition: @escaping (Bool) -> Void) {
        
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
    
    func getUserFromDB(with userID: String, complition: @escaping (DBUser) -> Void)
    {
        Firestore.firestore().collection("users").document(userID).getDocument { docSnapshot, error in
            if let error = error {
                print("Error getting user from DB:", error.localizedDescription)
                return
            }
            guard let snapshot = docSnapshot?.data(), let uid = snapshot["user_id"] as? String else {
                return
            }
            
//            let uid = snapshot["user_id"] as? String
            let date = snapshot["date_created"] as? Date
            let email = snapshot["email"] as? String
            let photoURL = snapshot["photo_url"] as? String
            
            let databaseUser = DBUser(uid: uid, date: date, email: email, photoURL: photoURL)
            
            complition(databaseUser)
        }
    }
    
    
}
