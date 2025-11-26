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
import Combine

//typealias RealtimeDBObserver = DatabaseReference

protocol RealtimeObservable {
    func removeAllObservers()
}

extension DatabaseReference: RealtimeObservable {}

final class RealtimeUserService: AuthUserProtocol
{
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
    func updateUserActiveStatus(isActive: Bool)
    {
        guard let authUserID = authUser?.uid else {return}
        let userData: [String: Any] = [
            "is_active": isActive
        ]
        usersReference.child(authUserID).updateChildValues(userData)
    }
    
    /// - user on disconnect setup
    func setupOnDisconnect() async throws
    {
        let userData: [String: Any] = [
            "is_active": false,
            "last_seen": Date().timeIntervalSince1970
        ]
        do {
            guard let authUserID = authUser?.uid else {return}
            self.onDisconnectRefListener = try await usersReference.child(authUserID).onDisconnectUpdateChildValues(userData)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func cancelOnDisconnect() async throws
    {
        try await onDisconnectRefListener?.cancelDisconnectOperations()
    }
    
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
                userRef.removeObserver(withHandle: handle)
            })
            .eraseToAnyPublisher()
    }
}
