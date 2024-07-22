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

import Foundation
import FirebaseDatabase
import FirebaseDatabaseSwift

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
}
