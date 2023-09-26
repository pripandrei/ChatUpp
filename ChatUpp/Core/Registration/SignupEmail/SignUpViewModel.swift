//
//  SignUpViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

enum UserRegistrationStatus {
    case success
    case failure
}

//MARK: - Email Signup view model

final class EmailSignupViewModel: EmailValidator {

    var email: String = ""
    var password: String = ""
    
    func validateEmailCredentials() throws {
        guard !email.isEmpty else {
            throw CredentialsError.emptyMail
        }
        guard !password.isEmpty else {
            throw CredentialsError.empyPassword
        }
        guard password.count > 6 else {
            throw CredentialsError.shortPassword
        }
    }
    
    func signUp(complition: @escaping (UserRegistrationStatus) -> Void) {
        AuthenticationManager.shared.signUpUser(email: email, password: password) { authDataResult in
            guard let authDataResult else {
                print("No authDataResult == nil")
                complition(.failure)
                return
            }
            UserManager.shared.createNewUser(with: authDataResult) { isCreated in
                if isCreated {
                   print("User was created!")
                } else {
                    print("Error creating user")
                }
            }
            complition(.success)
        }
    }
}
