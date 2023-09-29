//
//  LoginViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class LoginViewModel {
    
    var email: String = ""
    var password: String = ""
    
    var loginStatus: ObservableObject<LoginStatus?> = ObservableObject(nil)
}

//MARK: - Sign in with email

extension LoginViewModel: EmailValidator {
    
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
    
    func signInWithEmail() {
        AuthenticationManager.shared.signIn(email: email, password: password) { [weak self] authRestult in
            guard let _ = authRestult else {
                return
            }
            self?.loginStatus.value = .loggedIn
        }
    }
}

//MARK: - Sign in with google
    
extension LoginViewModel {
    func googleSignIn()
    {
        let helper = SignInGoogleHelper()
        
        helper.signIn { signInResult in
            guard let tokens = signInResult else {
                return
            }
            AuthenticationManager.shared.signInWithGoogle(usingTokens: tokens) { [weak self] authResultModel in
                guard let authResultModel = authResultModel else {
                    return
                }
                let dbUser = DBUser(auth: authResultModel)
                UserManager.shared.createNewUser(user: dbUser) { isCreated in
                   isCreated ? (self?.loginStatus.value = .loggedIn) : nil
                }
            }
        }
    }
}

