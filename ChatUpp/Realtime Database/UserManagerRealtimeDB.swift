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
/// - UserManagerRealtimeDB.shared.addObserverToUsers everywhere in code

import Foundation
import FirebaseDatabase
import FirebaseDatabaseSwift

typealias RealtimeDBObserver = DatabaseReference

final class UserManagerRealtimeDB {

    private init() {}
    
    static let shared = UserManagerRealtimeDB()
    private let usersRef = Database.database(url: "https://chatupp-e5b6c-default-rtdb.europe-west1.firebasedatabase.app").reference(withPath: "users")
    private var onDisconnectRefListener: DatabaseReference?
    
    /// - create user
    func createUser(user: DBUser) {
        let userData: [String: Any] = [
            "user_id": user.userId,
            "is_active": user.isActive,
            "last_seen": user.lastSeen!.timeIntervalSince1970
        ]
            usersRef.child(user.userId).setValue(userData)
    }
    
//    func createUser(user: DBUser) {
//        var userData: [String: Any] = [:]
//        
//        if let isActive = user.isActive {
//            userData["is_active"] = isActive
//        }
//        userData = [
//            "user_id": user.userId,
//            "last_seen": user.lastSeen!.timeIntervalSince1970
//        ]
//            usersRef.child(user.userId).setValue(userData)
//    }
    
    /// - update active status
    func updateUserActiveStatus(isActive: Bool) {
        guard let authUser = try? AuthenticationManager.shared.getAuthenticatedUser() else {return}
        let userData: [String: Any] = [
            "is_active": isActive
        ]
        usersRef.child(authUser.uid).updateChildValues(userData)
    }
    
    /// - user on disconnect setup
    func setupOnDisconnect() async throws
    {
        let userData: [String: Any] = [
            "is_active": false,
            "last_seen": Date().timeIntervalSince1970
        ]
        do {
            let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
            self.onDisconnectRefListener = try await usersRef.child(authUser.uid).onDisconnectUpdateChildValues(userData)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func cancelOnDisconnect() async throws {
        try await onDisconnectRefListener?.cancelDisconnectOperations()
    }
    
    func addObserverToUsers(_ userID: String, complition: @escaping (RealtimeDBUser) -> Void) -> RealtimeDBObserver {
        let userRef = usersRef.child(userID)

        userRef.observe(.value) { snapshot in
            do {
                let user = try snapshot.data(as: RealtimeDBUser.self)
                complition(user)
                print("success")
            } catch {
                print("Could not decode RealTimeDBUser: ", error.localizedDescription)
            }
        }
        return userRef
    }
}

struct RealtimeDBUser: Codable {
    let userId: String
    let isActive: Bool
    let lastSeen: Double
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isActive = "is_active"
        case lastSeen = "last_seen"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.lastSeen = try container.decode(Double.self, forKey: .lastSeen)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.lastSeen, forKey: .lastSeen)
    }
}

