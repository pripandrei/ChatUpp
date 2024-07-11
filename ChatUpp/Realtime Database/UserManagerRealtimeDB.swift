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
    
    private let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
    
    func setupOnDisconnect() async throws
    {
        let userData = ["is_active": false]
        do {
//            try await usersRef.child(authUser.uid).updateChildValues(userData)
//            let data = try await usersRef.child(authUser.uid).getData()
//            print("DATA:====", data)
            try await usersRef.child(authUser.uid).onDisconnectUpdateChildValues(userData)
        } catch {
            print(error.localizedDescription)
        }
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
}
