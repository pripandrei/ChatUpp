//
//  SettingsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import Combine

final class SettingsViewModel
{
    @Published private(set) var isUserSignedOut: Bool = false
    @Published private(set) var profileImageData: Data?
    private(set) var user: User!
    private(set) var authProvider: String!
 
    private var authUser : AuthenticatedUserData
    {
        try! AuthenticationManager.shared.getAuthenticatedUser()
    }
    
    init() {
        initiateSelf()
    }
    deinit {
        print("deinit settings view model")
    }
    
    private func initiateSelf()
    {
        self.retrieveDataFromDB()
        
        Task { @MainActor in
            do {
                try await self.getCurrentAuthProvider()
                try await self.fetchUserFromFirestoreDatabase()
                self.addUserToRealmDB()
                self.cacheProfileImage()
            } catch {
                print("Error while setup settings view model: \(error)")
            }
        }
    }
    
    func retrieveDataFromDB()
    {
        guard let realmUser = RealmDatabase.shared.retrieveSingleObject(ofType: User.self, primaryKey: authUser.uid) else {return}
        self.user = realmUser
        guard let pictureURL = user.photoUrl else {return}
        self.profileImageData = CacheManager.shared.retrieveData(from: pictureURL)
    }
    
    @MainActor
    private func fetchUserFromFirestoreDatabase() async throws
    {
        let firestoreUser = try await FirestoreUserService.shared.getUserFromDB(userID: authUser.uid)
        defer { self.user = firestoreUser }
        
        guard self.user.photoUrl != firestoreUser.photoUrl else { return }
        
        if let photoUrl = firestoreUser.photoUrl
        {
            self.profileImageData = try await FirebaseStorageManager.shared.getImage(from: .user(firestoreUser.id), imagePath: photoUrl)
        }
    }
    
    private func addUserToRealmDB()
    {
        RealmDatabase.shared.add(object: self.user)
    }
    
    private func cacheProfileImage()
    {
        guard let path = user.photoUrl,
              let data = profileImageData else {return}
        CacheManager.shared.saveData(data, toPath: path)
    }
    
    func getCurrentAuthProvider() async throws
    {
        self.authProvider = try await AuthenticationManager.shared.getAuthProvider()
    }
    
    func updateUserData(_ dbUser: User, _ photoData: Data?)
    {
        self.user = dbUser
        guard let photo = photoData else {return}
        self.profileImageData = photo
    }

    @MainActor
    func deleteUser() async throws
    {
        let deletedUserID = FirestoreUserService.mainDeletedUserID

        if authProvider == "google" {
            try await AuthenticationManager.shared.googleAuthReauthenticate()
        }
        
        try await AuthenticationManager.shared.deleteAuthUser()
        try await FirebaseChatService.shared.replaceUserId(user.id, with: deletedUserID)
        
        if let imgUrl = user.photoUrl {
            try await FirebaseStorageManager.shared.deleteImage(from: .user(user.id), imagePath: imgUrl)
        }
        try await FirestoreUserService.shared.deleteUserFromDB(userID: user.id)
    }
    
    @objc func signOut() async
    {
        do {
            RealtimeUserService.shared.updateUserActiveStatus(isActive: false)
            try await RealtimeUserService.shared.cancelOnDisconnect()
            try AuthenticationManager.shared.signOut()
            isUserSignedOut = true
        } catch {
            print("Error signing out", error.localizedDescription)
        }
    }
}
