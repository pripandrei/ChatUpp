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
    var user: User!
    var onUserFetched: (() -> ())?
    var authProvider: String!
    
    private var authUser : AuthDataResultModel
    {
        try! AuthenticationManager.shared.getAuthenticatedUser()
    }
    
    init() {
        Task {
            await self.retrieveDataFromDB()
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
    
    @MainActor
    private func retrieveDataFromDB()
    {
        guard let realmUser = RealmDataBase.shared.retrieveSingleObject(ofType: User.self, primaryKey: authUser.uid) else {return}
        self.user = realmUser
        guard let pictureURL = user.photoUrl else {return}
        self.imageData = CacheManager.shared.retrieveImageData(from: pictureURL)
//        self.onUserFetched?()
    }
    
    func updateUserData(_ dbUser: User, _ photoData: Data?) {
        self.user = dbUser
        guard let photo = photoData else {return}
        self.imageData = photo
    }

    
    func fetchUserFromDB() async throws {
        self.user = try await FirestoreUserService.shared.getUserFromDB(userID: authUser.uid)
//        self.imageData = try await FirestoreUserService.shared.getProfileImageData(urlPath: dbUser!.photoUrl)
        if let photoUrl = user.photoUrl {
            self.imageData = try await FirebaseStorageManager.shared.getUserImage(userID: user.id, path: photoUrl)
        }
//        onUserFetched?()
    }
    
    func getCurrentAuthProvider() async throws {
        self.authProvider = try await AuthenticationManager.shared.getAuthProvider()
    }

    func deleteUser() async throws
    {
        let deletedUserID = FirestoreUserService.mainDeletedUserID

        if authProvider == "google" {
            try await AuthenticationManager.shared.googleAuthReauthenticate()
        }
        try await AuthenticationManager.shared.deleteAuthUser()
        try await FirebaseChatService.shared.replaceUserId(user.id, with: deletedUserID)
        if let imgUrl = user.photoUrl {
            try await FirebaseStorageManager.shared.deleteProfileImage(ofUser: user.id, path: imgUrl)
        }
        try await FirestoreUserService.shared.deleteUserFromDB(userID: user.id)
    }
    
//    private func updateUserOnlineStatus() async throws {
//        guard let userId = dbUser?.userId else {return}
//        try await UserManager.shared.updateUser(with: userId, usingName: nil, onlineStatus: false)
//    }
    
//    func getUserImageAbsoluteURL() async throws -> URL?
//    {
//        guard let userID = user?.id, let url = user?.photoUrl else {return nil}
//        return try await FirebaseStorageManager.shared.getUserImageURL(userID: userID, path: url)
//    }
}
