//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/22/24.
//

import Foundation

final class ProfileDeletionViewModel {
    
    var verificationID: String?
    
    let dbUser: DBUser
    
    let userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    init(dbUser: DBUser) {
        self.dbUser = dbUser
    }
    
    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out", error.localizedDescription)
        }
    }
    
    func sendSMSCode() async throws {
        guard let phoneNumber = try AuthenticationManager.shared.getAuthenticatedUser().phoneNumber else {return}
        verificationID = try await AuthenticationManager.shared.sendSMSToPhone(number: phoneNumber)
    }
    
    func reauthenticateUser(usingCode code: String) async throws {
        guard let verificationID = self.verificationID else {throw UnwrappingError.nilValueFound("VerificationID is nil. Please request code first!")}
        
        try await AuthenticationManager.shared.phoneAuthReauthenticate(with: verificationID, verificationCode: code)
    }
    
    func deleteUser() async throws {
        let deletedUserID = UserManager.mainDeletedUserID
        
//        do {
            try await AuthenticationManager.shared.deleteAuthUser()
            try await ChatsManager.shared.replaceUserId(dbUser.userId, with: deletedUserID)
//            try await StorageManager.shared.deleteProfileImage(ofUser: dbUser.userId, path: dbUser.photoUrl!)
            try await UserManager.shared.deleteUserFromDB(userID: dbUser.userId)
//        } catch {
//            print("Error while deleting User!: ", error.localizedDescription)
//        }
    }
}
