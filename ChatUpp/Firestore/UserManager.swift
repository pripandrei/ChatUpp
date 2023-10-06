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

//MARK: - USER MANAGER

final class UserManager {
    
    static let shared = UserManager()
    
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userID: String) -> DocumentReference {
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
    
//    func getUserFromDB(userID: String, complition: @escaping (DBUser) -> Void) {
//        userDocument(userID: userID).getDocument(as: DBUser.self) { result in
//            do {
//                let user = try result.get()
//                complition(user)
//            } catch let e {
//                print("Error decoding user from DB \(e.localizedDescription)")
//            }
//        }
//    }
    
    func getUserFromDB(userID: String) async throws -> DBUser {
//        do {
            return try await userDocument(userID: userID).getDocument(as: DBUser.self)
//        } catch let error {
//            print("WTF", error.localizedDescription)
//            throw URLError(.badServerResponse)
//        }
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
