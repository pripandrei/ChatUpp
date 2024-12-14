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
    var user: User?
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
            RealtimeUserService.shared.updateUserActiveStatus(isActive: false)
            //            try await updateUserOnlineStatus()
            try await RealtimeUserService.shared.cancelOnDisconnect()
            try AuthenticationManager.shared.signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out", error.localizedDescription)
        }
    }
    
    func updateUserData(_ dbUser: User, _ photoData: Data?) {
        self.user = dbUser
        guard let photo = photoData else {return}
        self.imageData = photo
    }
    
    func fetchUserFromDB() async throws {
        let uderID = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await FirestoreUserService.shared.getUserFromDB(userID: uderID.uid)
//        self.imageData = try await UserManager.shared.getProfileImageData(urlPath: dbUser!.photoUrl)
        if let userID = user?.id, let photoUrl = user?.photoUrl {
            self.imageData = try await FirebaseStorageManager.shared.getUserImage(userID: userID, path: photoUrl)
        }
        onUserFetched?()
    }
    
    func getCurrentAuthProvider() async throws {
        self.authProvider = try await AuthenticationManager.shared.getAuthProvider()
    }

    func deleteUser() async throws {
        guard let userID = user?.id else {return}
        let deletedUserID = FirestoreUserService.mainDeletedUserID

        if authProvider == "google" {
            try await AuthenticationManager.shared.googleAuthReauthenticate()
        }
        try await AuthenticationManager.shared.deleteAuthUser()
        try await FirebaseChatService.shared.replaceUserId(userID, with: deletedUserID)
        if let imgUrl = user?.photoUrl {
            try await FirebaseStorageManager.shared.deleteProfileImage(ofUser: userID, path: imgUrl)
        }
        try await FirestoreUserService.shared.deleteUserFromDB(userID: userID)
    }
    
//    private func updateUserOnlineStatus() async throws {
//        guard let userId = dbUser?.userId else {return}
//        try await UserManager.shared.updateUser(with: userId, usingName: nil, onlineStatus: false)
//    }
}
