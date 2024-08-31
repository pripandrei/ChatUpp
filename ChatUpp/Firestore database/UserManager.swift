//
//  UserManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/16/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseDatabase

enum ResponseStatus {
    case success
    case failed
}

//MARK: - USER MANAGER

final class UserManager {
    
    static let mainDeletedUserID = "DeletedxE3btxSOXM2bRfkppe1P"
    
    static let shared = UserManager()
    
    private init() {}
    
    private let usersCollection = Firestore.firestore().collection(FirestoreCollection.users.rawValue)
    
    private func userDocument(userID: String) -> DocumentReference {
        usersCollection.document(userID)
    }
    
    let presenceRef = Database.database().reference(withPath: "users")
  
    // MARK: - CREATE NEW USER
    
    func createNewUser(user: DBUser) throws {
        try userDocument(userID: user.userId).setData(from: user, merge: false)
    }
    
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

    func updateUser(with userID: String,
                    usingName name: String?,
                    profilePhotoURL: String? = nil,
                    phoneNumber: String? = nil,
                    nickname: String? = nil,
                    onlineStatus: Bool? = nil) async throws
    {
        var userData: [String: Any] = [:]

        if let name = name {
            userData[DBUser.CodingKeys.name.rawValue] = name
        }
        if let profilePhoto = profilePhotoURL {
            userData[DBUser.CodingKeys.photoUrl.rawValue] = profilePhoto
        }
        if let phone = phoneNumber {
            userData[DBUser.CodingKeys.phoneNumber.rawValue] = phone
        }
        if let username = nickname {
            userData[DBUser.CodingKeys.nickname.rawValue] = username
        }
        try await userDocument(userID: userID).setData(userData, merge: true)
    }
    
    // MARK: - GET USER FROM DB
    
    func getUserFromDB(userID: String) async throws -> DBUser {
        return try await userDocument(userID: userID).getDocument(as: DBUser.self)
    }
    
    // MARK: - GET USER PROFILE IMAGE
    
    func getProfileImageData(urlPath: String?) async throws -> Data {
        guard let urlPath = urlPath,
              let url = URL(string: urlPath) else { throw UnwrappingError.nilValueFound("URL path for image Data is nil") }

        do {
            let (imgData,_) = try await URLSession.shared.data(from: url)
            return imgData
        } catch {
            print("Could not get the image from url: ", error.localizedDescription)
            throw error
        }
    }
    
    func getProfileImageData(urlPath: String?, completion: @escaping (Data?) -> Void) {
        guard let urlPath = urlPath,
              let url = URL(string: urlPath) else { return }
        
        let session = URLSession(configuration: .default)
       
        session.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Could not get profile image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }
            
            completion(data)
        }.resume()
    }
    
    // MARK: - Delete user form DB
    
    func deleteUserFromDB(userID: String) async throws {
        try await userDocument(userID: userID).delete()
    }
    
    // MARK: - Add listener to users
    
    @discardableResult
    func addListenerToUsers(_ usersID: [String], complitionHandler: @escaping ([DBUser], [DocumentChangeType]) -> Void) -> Listener {
        return usersCollection.whereField("user_id", in: usersID).addSnapshotListener { snapshot, error in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let documents = snapshot?.documentChanges else { print("No user to listen to"); return }
            
            var docType = [DocumentChangeType]()
            
            let users = documents.compactMap { userDocument in
                docType.append(userDocument.type)
                return try? userDocument.document.data(as: DBUser.self)
            }
            complitionHandler(users, docType)
        }
    }
}

// MARK: - Testing functions
extension UserManager {
    
    ///Remove all is_active fields
    func deleteAllIsActiveFieldsOnUsers() {
        usersCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            
            for document in querySnapshot?.documents ?? [] {
                let userData = document.data()
                
                if userData["is_active"] != nil {
                    document.reference.updateData([
                        "is_active": FieldValue.delete()
                    ]) { err in
                        if let err = err {
                            print("Error removing 'is_active' field: \(err)")
                        } else {
                            print("Successfully removed 'is_active' field for document \(document.documentID)")
                        }
                    }
                }
            }
        }
    }
}
