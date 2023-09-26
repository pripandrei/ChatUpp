//
//  UsernameRegistrationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

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
        let userID = try! AuthenticationManager.shared.getAuthenticatedUser().uid
        
        UserManager.shared.updateUser(with: userID, usingName: username) { [weak self] status in
            if status == .success {
                self?.finishRegistration.value = true
            }
        }
    }
}
