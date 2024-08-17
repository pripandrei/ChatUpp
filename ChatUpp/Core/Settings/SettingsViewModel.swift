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
    
    @objc func signOut() async {
        do {
            UserManagerRealtimeDB.shared.updateUserActiveStatus(isActive: false)
            //            try await updateUserOnlineStatus()
            try await UserManagerRealtimeDB.shared.cancelOnDisconnect()
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
    }
    
    func getCurrentAuthProvider() async throws {
        self.authProvider = try await AuthenticationManager.shared.getAuthProvider()
    }

    func deleteUser() async throws {
        guard let userID = dbUser?.userId else {return}
        let deletedUserID = UserManager.mainDeletedUserID

        if authProvider == "google" {
            try await AuthenticationManager.shared.googleAuthReauthenticate()
        }
        try await AuthenticationManager.shared.deleteAuthUser()
        try await ChatsManager.shared.replaceUserId(userID, with: deletedUserID)
        try await StorageManager.shared.deleteProfileImage(ofUser: userID, path: dbUser!.photoUrl!)
        try await UserManager.shared.deleteUserFromDB(userID: userID)
    }
    
//    func deleteUser() async throws {
//        let deletedUserID = UserManager.mainDeletedUserID
//    
//        try await AuthenticationManager.shared.deleteAuthUser()
//        try await ChatsManager.shared.replaceUserId(dbUser.userId, with: deletedUserID)
//        if let photoURL = dbUser.photoUrl {
//            try await StorageManager.shared.deleteProfileImage(ofUser: dbUser.userId, path: photoURL)
//        }
//        try await UserManager.shared.deleteUserFromDB(userID: dbUser.userId)
//    }
    
//    private func updateUserOnlineStatus() async throws {
//        guard let userId = dbUser?.userId else {return}
//        try await UserManager.shared.updateUser(with: userId, usingName: nil, onlineStatus: false)
//    }
}
