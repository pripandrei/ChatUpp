//
//  SettingsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class SettingsViewModel {

    var userIsSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    @objc func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            userIsSignedOut.value = true
        } catch {
            print("Error signing out")
        }
    }
    
    var setProfileName: ((String) -> Void)?
    
    func integrateName() {
        let authResult = try! AuthenticationManager.shared.getAuthenticatedUser()
        let dbUser = DBUser(userId: authResult.uid, dateCreated: Date(), email: authResult.email, photoUrl: authResult.photoURL)
        UserManager.shared.getUserFromDB(userID: dbUser.userId) { [weak self] user in
            DispatchQueue.main.async {
                self?.setProfileName?(user.userId)
            }
        }
//        UserManager.shared.getUserFromDB(with: dbUser.userID) { [weak self] dbUser in
//            print("Enterrr")
//            DispatchQueue.main.async {
//                self?.setProfileName?(dbUser.userID)
//            }
//        }
    }
}
