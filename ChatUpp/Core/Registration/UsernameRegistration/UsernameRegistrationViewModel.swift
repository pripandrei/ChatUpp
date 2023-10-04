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
    
//    var userPhoto: UIImage?
    
    func validateName() -> ValidationStatus {
        if !self.username.isEmpty {
            return .valid
        }
        return .invalid
    }
    
    let finishRegistration: ObservableObject<Bool?> = ObservableObject(nil)
    
    func updateUser() {
        guard let userId = AuthenticationManager.shared.getAuthenticatedUser()?.uid else {
            print("Could not update user: AuthUser is nil")
            return
        }
        UserManager.shared.updateUser(with: userId, usingName: username) { [weak self] status in
            if status == .success {
                self?.finishRegistration.value = true
            }
        }
    }
}
