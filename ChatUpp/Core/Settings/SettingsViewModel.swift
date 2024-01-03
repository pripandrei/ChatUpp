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
    
    func integrateName() async {
//        let authResult = try! AuthenticationManager.shared.getAuthenticatedUser()
//        let dbUser = DBUser(auth: authResult)
//        UserManager.shared.getUserFromDB(userID: dbUser.userId) { [weak self] user in
//            DispatchQueue.main.async {
////                self?.setProfileName?(user.userId)
//            }
//        }
    }

    
    var authUser: AuthDataResultModel? {
        let user = try? AuthenticationManager.shared.getAuthenticatedUser()
        if user != nil {
            return user
        }
        return nil
    }
}
