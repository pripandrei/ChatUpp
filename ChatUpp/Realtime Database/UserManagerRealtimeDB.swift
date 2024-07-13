//
//  UserManagerRealtimeDB.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 7/8/24.
//

import Foundation
import FirebaseDatabase
import FirebaseDatabaseSwift

final class UserManagerRealtimeDB {

    static let shared = UserManagerRealtimeDB()
    private let usersRef = Database.database(url: "https://chatupp-e5b6c-default-rtdb.europe-west1.firebasedatabase.app").reference(withPath: "users")
    private var onDisconnectRefListener: DatabaseReference?
//    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    private init() {}

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
    
    func createUser(user: DBUser) {
        let userData: [String: Any] = [
            "user_id": user.userId,
            "is_active": user.isActive,
            "last_seen": user.lastSeen!.timeIntervalSince1970
        ]
            usersRef.child(user.userId).setValue(userData)
    }
}
