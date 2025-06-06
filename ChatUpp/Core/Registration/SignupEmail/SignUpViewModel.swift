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

    func signUp(complition: @escaping (UserRegistrationStatus) -> Void) {
        AuthenticationManager.shared.signUpUser(email: email, password: password) { authDataResult in
            guard let authDataResult else {
                print("No authDataResult == nil")
                complition(.failure)
                return
            }
            let dbUser = User(auth: authDataResult)
            
            FirestoreUserService.shared.createNewUser(user: dbUser) { isCreated in
                if isCreated {
                   print("User was created!")
                } else {
                    print("Error creating user during sign up")
                }
            }
            RealtimeUserService.shared.createUser(user: dbUser)
            complition(.success)
        }
    }
}
