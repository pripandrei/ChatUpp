//
//  SettingsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class SettingsViewModel {

    private(set) var userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    var dbUser: DBUser?
    private(set) var imageData: Data?
    var onUserFetched: (() -> ())?
//    var updateUserData: ((_ name: String?,
//                                _ phone: String?,
//                                _ nickname: String?,
//                                _ profilePhoto: Data?) -> Void)?
    
    init() {
        Task {
            try await self.fetchUserFromDB()
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
        if let userID = dbUser?.userId, let photoUrl = dbUser?.photoUrl {
            self.imageData = try await StorageManager.shared.getUserImage(userID: userID, path: photoUrl)
        }
        onUserFetched?()
    }
    
    func deleteUser() async {
        guard let userID = dbUser?.userId else {return}
        let deletedUserID = UserManager.mainDeletedUserID
        
        do {
            try await ChatsManager.shared.replaceUserId(userID, with: deletedUserID)
            try await AuthenticationManager.shared.deleteAuthUser()
            try await UserManager.shared.deleteUserFromDB(userID: userID)
        } catch {
            print("Error delete User!: ", error.localizedDescription)
        }
    }
    
//    func signOutOnAccountDeletion() async {
////        Task {
//            do {
//                try await AuthenticationManager.shared.foreceRefreshIDToken()
//            } catch {
//                signOut()
//                print("Error while signing out on user deletion: ", error)
//            }
//            
//            
////            do {
////                try await AuthenticationManager.shared.signOutOnDeletion()
////                userIsSignedOut.value = true
////            } catch {
////                print("Error while signing out on user deletion: ", error)
////            }
////        }
//    }
    
//    var authUser: AuthDataResultModel? {
//        let user = try? AuthenticationManager.shared.getAuthenticatedUser()
//        if user != nil {
//            return user
//        }
//        return nil
//    }
}
