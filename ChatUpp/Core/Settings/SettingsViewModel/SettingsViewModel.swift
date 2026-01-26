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
    @Published private(set) var user: User? // user will be nil only on first app run, while not fetched
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
            
            while NetworkMonitor.shared.isReachable == false
            {
                try await Task.sleep(for: .seconds(8))
            }
            
            do {
                try await self.getCurrentAuthProvider()
                try await self.fetchUserFromFirestoreDatabase()
            } catch {
                print("Error while setup settings view model: \(error)")
            }
        }
    }
    
    func retrieveDataFromDB()
    {
        guard let realmUser = RealmDatabase.shared.retrieveSingleObject(ofType: User.self,
                                                                        primaryKey: authUser.uid) else {return}
        self.user = realmUser
        guard let pictureURL = user?.photoUrl else {return}
        self.profileImageData = CacheManager.shared.retrieveData(from: pictureURL)
    }
    
    // just to trigger nickname update if cancel button was taped
    func updateUser()
    {
        user = user
    }
    
    @MainActor
    private func fetchUserFromFirestoreDatabase() async throws
    {
        let firestoreUser = try await FirestoreUserService.shared.getUserFromDB(userID: authUser.uid)
        defer {
            self.user = firestoreUser
            self.addUserToRealmDB()
        }
        
        guard self.user?.photoUrl != firestoreUser.photoUrl || !CacheManager.shared.doesFileExist(at: self.user?.photoUrl ?? "") else { return }
        
        if let photoUrl = firestoreUser.photoUrl
        {
            self.profileImageData = try await FirebaseStorageManager.shared.getImage(from: .user(firestoreUser.id), imagePath: photoUrl)
            self.cacheProfileImage()
        }
    }
    
    private func addUserToRealmDB()
    {
        guard let user = self.user else {return}
        RealmDatabase.shared.add(object: user)
    }
    
    private func cacheProfileImage()
    {
        guard let path = user?.photoUrl,
              let data = profileImageData else {return}
        CacheManager.shared.saveData(data, toPath: path)
    }
    
    func getCurrentAuthProvider() async throws
    {
        self.authProvider = try await AuthenticationManager.shared.getAuthProvider()
    }
    
//    func updateUserData(_ dbUser: User, _ photoData: Data?)
//    {
//        self.user = dbUser
//        guard let photo = photoData else {return}
//        self.profileImageData = photo
//    }

    @MainActor
    func deleteUser() async throws
    {
        guard let user = self.user else {return}
        let deletedUserID = FirestoreUserService.mainDeletedUserID

        if authProvider == "google.com" {
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
