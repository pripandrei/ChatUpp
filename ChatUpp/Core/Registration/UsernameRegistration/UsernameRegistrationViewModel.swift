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
        guard let id = try? AuthenticationManager.shared.getAuthenticatedUser().uid else {
            print("error updading user: authUser is nil")
            return
        }
        Task {
            do {
                try await UserManager.shared.updateUser(with: id, usingName: username)
                finishRegistration.value = true
            } catch {
                print("Error updating user on creation: ", error)
            }
        }
    }

}
