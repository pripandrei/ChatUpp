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
    
//    var setProfileName: ((String) -> Void)?
    
    var onUserFetch: ((Data, String) -> Void)?
    
    func fetchUserFromDB() async throws {
        let uderID = try AuthenticationManager.shared.getAuthenticatedUser()
        let dbUser = try await UserManager.shared.getUserFromDB(userID: uderID.uid)
        let imageData = try await UserManager.shared.getProfileImageData(urlPath: dbUser.photoUrl)
        
        onUserFetch?(imageData,dbUser.name!)
    }
    
    var authUser: AuthDataResultModel? {
        let user = try? AuthenticationManager.shared.getAuthenticatedUser()
        if user != nil {
            return user
        }
        return nil
    }
}
