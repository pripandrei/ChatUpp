//
//  SettingsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class SettingsViewModel {

    private(set) var userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    private(set) var dbUser: DBUser?
    private(set) var imageData: Data?
    var onUserFetch: ((_ name: String?,
                                _ phone: String?,
                                _ nickname: String?,
                                _ profilePhoto: Data?) -> Void)?
    
    @objc func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out")
        }
    }
    
    init() {
        Task {
            try await self.fetchUserFromDB()
        }
    }
    
    func fetchUserFromDB() async throws {
        let uderID = try AuthenticationManager.shared.getAuthenticatedUser()
        self.dbUser = try await UserManager.shared.getUserFromDB(userID: uderID.uid)
//        self.imageData = try await UserManager.shared.getProfileImageData(urlPath: dbUser!.photoUrl)
        self.imageData = try await StorageManager.shared.getUserImage(userID: dbUser!.userId, path: dbUser!.photoUrl!)
        onUserFetch?(dbUser?.name,dbUser?.phoneNumber,dbUser?.nickname,imageData)
    }
    
    var authUser: AuthDataResultModel? {
        let user = try? AuthenticationManager.shared.getAuthenticatedUser()
        if user != nil {
            return user
        }
        return nil
    }
}
