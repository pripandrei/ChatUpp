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
import Combine

enum ResponseStatus {
    case success
    case failed
}

//MARK: - USER MANAGER

final class FirestoreUserService {
    
    static let mainDeletedUserID = "DeletedxE3btxSOXM2bRfkppe1P"
    
    static let shared = FirestoreUserService()
    
    private init() {}
    
    private let usersCollection = Firestore.firestore().collection(FirestoreCollection.users.rawValue)
    
    private func userDocument(userID: String) -> DocumentReference {
        usersCollection.document(userID)
    }
    
    let presenceRef = Database.database().reference(withPath: "users")
  
    // MARK: - CREATE NEW USER
    
    func createNewUser(user: User) throws {
        try userDocument(userID: user.id).setData(from: user, merge: false)
    }
    
    func createNewUser(user: User, _ complition: @escaping (Bool) -> Void) {
        
//         Same document should not be updated if it already exists in db (creation of new user updates it)
        userDocument(userID: user.id).getDocument { [weak self] (documentSnapshot, error) in
            
            guard error == nil else { print(error!) ; return }
            guard let self = self else {return}
            
            if let document = documentSnapshot, !document.exists {
                try? self.userDocument(userID: user.id).setData(from: user, merge: false) { error in
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
            userData[User.CodingKeys.name.rawValue] = name
        }
        if let profilePhoto = profilePhotoURL {
            userData[User.CodingKeys.photoUrl.rawValue] = profilePhoto
        }
        if let phone = phoneNumber {
            userData[User.CodingKeys.phoneNumber.rawValue] = phone
        }
        if let username = nickname {
            userData[User.CodingKeys.nickname.rawValue] = username
        }
        try await userDocument(userID: userID).setData(userData, merge: true)
    }
    
    // MARK: - GET USER FROM DB
    
    func getUserFromDB(userID: String) async throws -> User {
        return try await userDocument(userID: userID).getDocument(as: User.self)
    }
    
    func fetchUsers(with IDs: [String]) async throws -> [User]
    {
        let users = try await usersCollection
            .whereField(User.CodingKeys.id.rawValue, in: IDs)
            .getDocuments(as: User.self)
        
        return users
    }
    
    /// Temporarly
    func fetchUsers() async throws -> [User] {
        let limit = 50
        return try await usersCollection.limit(to: limit).getDocuments(as: User.self)
//        return try await userDocument(userID: userID).getDocument(as: User.self, source: .server)
    }
    
    // MARK: - GET USER PROFILE IMAGE
    
//    func getProfileImageData(urlPath: String?) async throws -> Data {
//        guard let urlPath = urlPath,
//              let url = URL(string: urlPath) else { throw UnwrappingError.nilValueFound("URL path for image Data is nil") }
//
//        do {
//            let (imgData,_) = try await URLSession.shared.data(from: url)
//            return imgData
//        } catch {
//            print("Could not get the image from url: ", error.localizedDescription)
//            throw error
//        }
//    }
    
    // MARK: - Delete user form DB
    
    func deleteUserFromDB(userID: String) async throws {
        try await userDocument(userID: userID).delete()
    }
    
    // MARK: - Add listener to users
    
//    @discardableResult
//    func addListenerToUsers(_ usersID: [String], complitionHandler: @escaping ([User], [DocumentChangeType]) -> Void) -> Listener
//    {
//        return usersCollection.whereField("user_id", in: usersID).addSnapshotListener { snapshot, error in
//            guard error == nil else { print(error!.localizedDescription); return }
//            guard let documents = snapshot?.documentChanges else { print("No user to listen to"); return }
//            
//            var docType = [DocumentChangeType]()
//            
//            let users = documents.compactMap { userDocument in
//                docType.append(userDocument.type)
//                return try? userDocument.document.data(as: User.self)
//            }
//            complitionHandler(users, docType)
//        }
//    }
    
    @discardableResult
    func addListenerToUsers(_ usersID: [String]) -> AnyPublisher<DatabaseChangedObject<User>, Never>
    {
        let subject = PassthroughSubject<DatabaseChangedObject<User>, Never>()
        
        let listener = usersCollection.whereField("user_id", in: usersID).addSnapshotListener { snapshot, error in
            
            guard error == nil else { print(error!.localizedDescription); return }
            guard let documents = snapshot?.documentChanges else { print("No user to listen to"); return }
            
            documents.forEach { userDocument in
                guard let user = try? userDocument.document.data(as: User.self) else {return}
                let updatedChatObject = DatabaseChangedObject(data: user, changeType: userDocument.type)
                subject.send(updatedChatObject)
            }
        }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }
}

// MARK: - Testing functions
extension FirestoreUserService {
    
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


struct ObjectsFetchingLimit
{
    static let messages: Int = 30
    static let users: Int = 100
    static let chats: Int = 100
}
