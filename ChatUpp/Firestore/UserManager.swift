//
//  UserManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/16/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


enum ResponseStatus {
    case success
    case failed
}

//MARK: - USER MANAGER

final class UserManager {
    
    static let shared = UserManager()
    
    private init() {}
    
    private let userCollection = Firestore.firestore().collection(FirestoreCollection.users.rawValue)
    
    private func userDocument(userID: String) -> DocumentReference {
        userCollection.document(userID)
    }
    
    // MARK: - CREATE NEW USER
    
//    
//    func createNewUser(user: DBUser) async throws -> UserCreationStatus {
//        if let _ = try? await getUserFromDB(userID: user.userId) {
//            return .userExists
//        }
//        
//        do {
//            try userDocument(userID: user.userId).setData(from: user, merge: false)
//            return .userIsCreated
//        } catch {
//            throw error
//        }
//    }
//    
    
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
                    nickname: String? = nil) async throws
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
    
//    func updateUser(with userID: String,
//                    usingName name: String,
//                    profilePhotoURL: String? = nil,
//                    phoneNumber: String? = nil,
//                    nickname: String? = nil,
//                    complition: @escaping (ResponseStatus) -> Void)
//    {
//        var userData: [String: Any] = [
//            DBUser.CodingKeys.name.rawValue : name
//        ]
//        if let profilePhoto = profilePhotoURL {
//            userData[DBUser.CodingKeys.photoUrl.rawValue] = profilePhoto
//        }
//        if let phone = phoneNumber {
//            userData[DBUser.CodingKeys.phoneNumber.rawValue] = phone
//        }
//        if let username = nickname {
//            userData[DBUser.CodingKeys.nickname.rawValue] = username
//        }
//
//        userDocument(userID: userID).setData(userData, merge: true) { error in
//            if let error = error {
//                print("There was an error updating username: ", error.localizedDescription)
//                complition(.failed)
//                return
//            }
//            complition(.success)
//        }
//    }
    
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
    
    func deleteUserFromDB() {
        
    }
}

