//
//  UserManagerRealtimeDB.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/8/24.
//

/// IMPORTANT: Firebase functions were implemented in order to listen for changes inside Realtime database
//  and update/mirror them to Firestore database,
//  so updating "is_active" and "last_seen" fields of user will only be made inside Realtime DB,
//  and after that, Firebase functions will take care of mirroring update to Firestore DB
//  You can find them inside ChatUpp/functions/index.js

/// UPDATE!: Firebase functions are currently disabled (Firebase plan was modified to Spark Plan)
/// Aditional functionallity was implemented inside project to cover all Firebase functions functionality
/// Firebase functions will be automatically enabled when plan will be updated to Blaze Plan

// TODO: Things to remove after transitioning back to listening for is_active and "last_seen" fields from Firebase DB:
/// - DBUser.updateActiveStatus
/// - UserManagerRealtimeDB.shared.addObserverToUsers everywhere in code
/// - DBUser.isActive change from optional

import Foundation
import FirebaseDatabase

//import FirebaseDatabaseSwift
import Combine

//typealias RealtimeDBObserver = DatabaseReference

protocol RealtimeObservable {
    func removeAllObservers()
}

extension DatabaseReference: RealtimeObservable {}

final class RealtimeUserService: AuthUserProtocol {
    
    private init() {}
    
    static let shared = RealtimeUserService()
    private let usersReference = Database.database(url: "https://chatupp-e5b6c-default-rtdb.europe-west1.firebasedatabase.app").reference(withPath: "users")
    private var onDisconnectRefListener: DatabaseReference?
    
    /// - create user
    func createUser(user: User) {
        let userData: [String: Any?] = [
            "user_id": user.id,
            "is_active": user.isActive,
            "last_seen": user.lastSeen!.timeIntervalSince1970
        ]
            usersReference.child(user.id).setValue(userData)
    }
    
    /// - update active status
    func updateUserActiveStatus(isActive: Bool) {
        let userData: [String: Any] = [
            "is_active": isActive
        ]
        usersReference.child(authUser.uid).updateChildValues(userData)
    }
    
    /// - user on disconnect setup
    func setupOnDisconnect() async throws
    {
        let userData: [String: Any] = [
            "is_active": false,
            "last_seen": Date().timeIntervalSince1970
        ]
        do {
            self.onDisconnectRefListener = try await usersReference.child(authUser.uid).onDisconnectUpdateChildValues(userData)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func cancelOnDisconnect() async throws {
        try await onDisconnectRefListener?.cancelDisconnectOperations()
    }
    
//    func addObserverToUsers(_ userID: String, complition: @escaping (User) -> Void) -> RealtimeObservable
//    {
//        let userRef = usersReference.child(userID)
//
//        userRef.observe(.value) { snapshot in
//            do {
//                let user = try snapshot.data(as: User.self)
//                complition(user)
//            } catch {
//                print("Could not decode Realtime DBUser: ", error.localizedDescription)
//            }
//        }
//        return userRef
//    }
//    
    func addObserverToUsers(_ userID: String) -> AnyPublisher<User, Never>
    {
        let subject = PassthroughSubject<User, Never>()
        let userRef = usersReference.child(userID)

        let handle = userRef.observe(.value) { snapshot in
            do {
                let user = try snapshot.data(as: User.self)
                subject.send(user)
            } catch {
                print("Could not decode Realtime DBUser: ", error.localizedDescription)
            }
        }
        return subject
            .handleEvents(receiveCancel: {
//                userRef.removeAllObservers()
                userRef.removeObserver(withHandle: handle)
            })
            .eraseToAnyPublisher()
    }
}





//MARK: - Currently not in use (DBUser is used instead)
//
//struct RealtimeDBUser: Codable {
//    let userId: String
//    let isActive: Bool
//    let lastSeen: Double
//    
//    enum CodingKeys: String, CodingKey {
//        case userId = "user_id"
//        case isActive = "is_active"
//        case lastSeen = "last_seen"
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.userId = try container.decode(String.self, forKey: .userId)
//        self.isActive = try container.decode(Bool.self, forKey: .isActive)
//        self.lastSeen = try container.decode(Double.self, forKey: .lastSeen)
//    }
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.userId, forKey: .userId)
//        try container.encode(self.isActive, forKey: .isActive)
//        try container.encode(self.lastSeen, forKey: .lastSeen)
//    }
//}
