//
//  UserManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/16/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


enum ResposneStatus {
    case success
    case failed
}

//MARK: - Firestore DB User

struct DBUser: Codable {
    let userId: String
//    let name: String
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
}

//MARK: - USER MANAGER

final class UserManager {
    
    static let shared = UserManager()
    
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userID: String) -> DocumentReference {
        userCollection.document(userID)
    }

    var encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    var decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    // MARK: - CREATE NEW USER
    
    func createNewUser(user: DBUser, _ complition: @escaping (Bool) -> Void) {
        
        // Same document should not be updated if it already exists in db (creation of new user updates it)
        userDocument(userID: user.userId).checkDocumentExistence(completion: { [weak self] exists in
            guard let self = self else {return}
            if !exists {
                try? self.userDocument(userID: user.userId).setData(from: user, merge: false, encoder: self.encoder) { error in
                    if error != nil {
                        print("Error creating user document: \(error!.localizedDescription)")
                        complition(false)
                    }
                    complition(true)
                }
            } else {
                complition(true)
            }
        })
    }
    
    // MARK: - UPDATE USER
    
    func updateUser(with userID: String, usingName name: String, complition: @escaping (ResposneStatus) -> Void) {
        let userData: [String: Any] = [
            "name" : name
        ]
        userDocument(userID: userID).setData(userData, merge: true) { error in
            if let error = error {
                print("There was an error updating username: ", error.localizedDescription)
                complition(.failed)
                return
            }
            complition(.success)
        }
    }
    
    // MARK: - GET USER FROM DM
    
    func getUserFromDB(userID: String, complition: @escaping (DBUser) -> Void) {
        userDocument(userID: userID).getDocument(as: DBUser.self, decoder: decoder) { result in
            do {
                let user = try result.get()
                complition(user)
            } catch let e {
                print("Error decoding user from DB \(e)")
            }
        }
    }
    
    func getUserFromDB(with userID: String, complition: @escaping (DBUser) -> Void)
    {
        userDocument(userID: userID).getDocument { docSnapshot, error in
            if let error = error {
                print("Error getting user from DB:", error.localizedDescription)
                return
            }
            guard let snapshot = docSnapshot?.data(),
                  let uid = snapshot["user_id"] as? String else {
                return
            }
            
//            let uid = snapshot["user_id"] as? String
            let date = snapshot["date_created"] as? Date
            let email = snapshot["email"] as? String
            let photoURL = snapshot["photo_url"] as? String
            
            let databaseUser = DBUser(userId: uid, dateCreated: date, email: email, photoUrl: photoURL)
            
            complition(databaseUser)
        }
    }
}

extension DocumentReference {
    public func checkDocumentExistence(completion: @escaping (Bool) -> Void) {
        self.getDocument { (docSnapshot, error) in
            if let error = error {
                print("Error getting document: \(error)")
                completion(false)
                return
            }
            guard let snapshot = docSnapshot else {
                completion(false)
                return
            }
            completion(snapshot.exists)
        }
    }
}
