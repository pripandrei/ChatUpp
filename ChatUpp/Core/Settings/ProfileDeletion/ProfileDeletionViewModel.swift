//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/22/24.
//

import Foundation

final class ProfileDeletionViewModel {
    
    var verificationID: String?
    
    let user: User
    
    let userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    init(user: User) {
        self.user = user
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
        let deletedUserID = FirestoreUserService.mainDeletedUserID
    
        try await AuthenticationManager.shared.deleteAuthUser()
        try await FirebaseChatService.shared.replaceUserId(user.id, with: deletedUserID)
        if let photoURL = user.photoUrl {
            try await FirebaseStorageManager.shared.deleteImage(from: .user(user.id), imagePath: photoURL)
        }
        try await FirestoreUserService.shared.deleteUserFromDB(userID: user.id)
    }
}
