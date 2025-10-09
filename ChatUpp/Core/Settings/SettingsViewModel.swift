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
    private(set) var isUserSignedOut: ObservableObject<Bool> = ObservableObject(false)
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
//        print("deinit settings view model")
    }
    
    private func initiateSelf()
    {
        Task { @MainActor in
            self.retrieveDataFromDB()
            try await self.fetchUserFromDB()
            try await self.getCurrentAuthProvider()
            self.addUserToRealmDB()
            self.cacheProfileImage()
        }
    }
    
    func retrieveDataFromDB()
    {
        guard let realmUser = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: authUser.uid) else {return}
        self.user = realmUser
        guard let pictureURL = user.photoUrl else {return}
        self.profileImageData = CacheManager.shared.retrieveData(from: pictureURL)
    }
    
    private func fetchUserFromDB() async throws
    {
        self.user = try await FirestoreUserService.shared.getUserFromDB(userID: authUser.uid)
        
        if let photoUrl = user.photoUrl {
            self.profileImageData = try await FirebaseStorageManager.shared.getImage(from: .user(user.id), imagePath: photoUrl)
        }
    }
    
    private func addUserToRealmDB()
    {
        RealmDataBase.shared.add(object: self.user)
    }
    
    private func cacheProfileImage()
    {
        guard let path = user.photoUrl, let data = profileImageData else {return}
        CacheManager.shared.saveData(data, toPath: path)
    }
    
    func getCurrentAuthProvider() async throws {
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
    
    @objc func signOut() async {
        do {
            RealtimeUserService.shared.updateUserActiveStatus(isActive: false)
            try await RealtimeUserService.shared.cancelOnDisconnect()
            try AuthenticationManager.shared.signOut()
            isUserSignedOut.value = true
        } catch {
            print("Error signing out", error.localizedDescription)
        }
    }
}
