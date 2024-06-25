//
//  UsernameRegistrationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

enum ValidationStatus {
    case valid
    case invalid
}

//MARK: - Username registration View Model
 
final class UsernameRegistrationViewModel {
    
    var username: String = ""
    var profileImageData: Data?
    let finishRegistration: ObservableObject<Bool?> = ObservableObject(nil)
    
//    var userPhoto: UIImage?
    
    func validateName() -> ValidationStatus {
        if !self.username.isEmpty {
            return .valid
        }
        return .invalid
    }
    
    private var authUser: AuthDataResultModel {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            return user
        }
        fatalError("user is missing")
    }
    
    private func saveProfileImageToStorage() async throws -> String? {
        if let profileImageData = profileImageData {
            let (_, name) = try await StorageManager.shared.saveUserImage(data: profileImageData, userId: authUser.uid)
            return name
        }
        return nil
    }
    
    func updateUser() {
        Task {
            do {
                // if user will not add profile photo saveProfileImageToStorage will return nil
                // and default profile picture will be used
                let profilePhotoURL = try await saveProfileImageToStorage()
                try await UserManager.shared.updateUser(with: authUser.uid, usingName: username, profilePhotoURL: profilePhotoURL)
                finishRegistration.value = true
            } catch {
                print("Error updating user on creation: ", error)
            }
        }
    }

}
