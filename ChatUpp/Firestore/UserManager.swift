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

struct DBUser: Codable
{
    let userId: String
    let name: String? 
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.name = auth.name
        self.dateCreated = Date()
        self.email = auth.email
        self.photoUrl = auth.photoURL
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name = "name"
        case dateCreated = "date_created"
        case email = "email"
        case photoUrl = "photo_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
    }
}

//MARK: - USER MANAGER

final class UserManager {
    
    static let shared = UserManager()
    
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userID: String) -> DocumentReference {
//        userCollection.
        userCollection.document(userID)
    }
    
    // MARK: - CREATE NEW USER
    
    func createNewUser(user: DBUser, _ complition: @escaping (Bool) -> Void) {
        
//         Same document should not be updated if it already exists in db (creation of new user updates it)
        userDocument(userID: user.userId).getDocument { [weak self] (documentSnapshot, error) in
            
            guard error == nil else { print(error!) ; return }
            guard let self = self else {return}
            
            if let document = documentSnapshot, !document.exists {
                try? self.userDocument(userID: user.userId).setData(from: user, merge: false) { error in
                    if error != nil {
                        print("Error creating user document: \(error!.localizedDescription)")
                        complition(false)
                    }
                    complition(true)
                }
            } else {
                complition(true)
            }
        }
    }
    
    // MARK: - UPDATE USER
    
    func updateUser(with userID: String, usingName name: String, complition: @escaping (ResposneStatus) -> Void) {
        let userData: [String: Any] = [
            DBUser.CodingKeys.name.rawValue : name
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
    
    // MARK: - GET USER FROM DB
    
    func getUserFromDB(userID: String, complition: @escaping (DBUser) -> Void) {
        userDocument(userID: userID).getDocument(as: DBUser.self) { result in
            do {
                let user = try result.get()
                complition(user)
            } catch let e {
                print("Error decoding user from DB \(e)")
            }
        }
    }
}





//extension DocumentReference {
//    public func checkDocumentExistence(completion: @escaping (Bool) -> Void) {
//        self.getDocument { (docSnapshot, error) in
//            if let error = error {
//                print("Error getting document: \(error)")
//                completion(false)
//                return
//            }
//            guard let snapshot = docSnapshot else {
//                completion(false)
//                return
//            }
//            completion(snapshot.exists)
//        }
//    }
//}
