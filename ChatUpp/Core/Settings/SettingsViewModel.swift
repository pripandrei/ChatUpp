//
//  SettingsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class SettingsViewModel {

    private(set) var userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    private(set) var imageData: Data?
    var dbUser: DBUser?
    var onUserFetched: (() -> ())?
    var authProvider: String!
    
    init() {
        Task {
            try await self.fetchUserFromDB()
            try await self.getCurrentAuthProvider()
        }
    }
    
    @objc func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out", error.localizedDescription)
        }
    }
    
    func updateUserData(_ dbUser: DBUser, _ photoData: Data?) {
        self.dbUser = dbUser
        guard let photo = photoData else {return}
        self.imageData = photo
    }
    
    func fetchUserFromDB() async throws {
        let uderID = try AuthenticationManager.shared.getAuthenticatedUser()
        self.dbUser = try await UserManager.shared.getUserFromDB(userID: uderID.uid)
//        self.imageData = try await UserManager.shared.getProfileImageData(urlPath: dbUser!.photoUrl)
        if let userID = dbUser?.userId, let photoUrl = dbUser?.photoUrl {
            self.imageData = try await StorageManager.shared.getUserImage(userID: userID, path: photoUrl)
        }
        onUserFetched?()
//        updateUserData?(dbUser?.name,dbUser?.phoneNumber,dbUser?.nickname,imageData)
    }
    
//    var authProvider: ObservableObject<String?> = ObservableObject(nil)
    
    func getCurrentAuthProvider() async throws {
//        self.authProvider.value = try await AuthenticationManager.shared.getAuthProvider()
        self.authProvider = try await AuthenticationManager.shared.getAuthProvider()
    }
    
//    func reauthenticateGoogleUser() async throws {
//        try await AuthenticationManager.shared.googleAuthReauthenticate()
//    }
    
    func deleteUser() async throws {
        guard let userID = dbUser?.userId else {return}
        let deletedUserID = UserManager.mainDeletedUserID
        //        let chats = try await ChatsManager.shared.getUserChatsFromDB(userID)
        
        //        do {
        try await AuthenticationManager.shared.googleAuthReauthenticate()
        try await AuthenticationManager.shared.getAuthProvider()
        //            try await AuthenticationManager.shared.initiateReauthentication()
        //            try await AuthenticationManager.shared.foreceRefreshIDToken()
        try await AuthenticationManager.shared.deleteAuthUser()
        try await ChatsManager.shared.replaceUserId(userID, with: deletedUserID)
        try await StorageManager.shared.deleteProfileImage(ofUser: userID, path: dbUser!.photoUrl!)
        try await UserManager.shared.deleteUserFromDB(userID: userID)
        //        } catch {
        //            print("Error while deleting User!: ", error.localizedDescription)
        //        }
    }
}
