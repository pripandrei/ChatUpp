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
    
    private init() {}
    
    private let usersRef = Database.database(url: "https://chatupp-e5b6c-default-rtdb.europe-west1.firebasedatabase.app").reference(withPath: "users")
    private var onDisconnectRefListener: DatabaseReference?
//    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    func setupOnDisconnect() async throws
    {
        let userData: [String: Any] = [
            "is_active": false,
            "last_seen": Date().timeIntervalSince1970
        ]
        do {
            let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
//            try await usersRef.child(authUser.uid).updateChildValues(userData)
//            let data = try await usersRef.child(authUser.uid).getData()
//            print("DATA:====", data)
            self.onDisconnectRefListener = try await usersRef.child(authUser.uid).onDisconnectUpdateChildValues(userData)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func cancelOnDisconnect() async throws {
        try await onDisconnectRefListener?.cancelDisconnectOperations()
    }
    
    let connectedRef = Database.database().reference(withPath: ".info/connected")
    func checkConnection() {
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected to Firebase")
            } else {
                print("Not connected to Firebase")
            }
        })
    }
    
    func createUser(user: DBUser) {
        let userData: [String: Any] = [
            "user_id": user.userId,
            "is_active": user.isActive,
            "last_seen": user.lastSeen!.timeIntervalSince1970
        ]
//        do{
            usersRef.child(user.userId).setValue(userData)
//        } catch {
//            print("Error while creating user inside Realtime database: ", error.localizedDescription)
//        }
    }
}
