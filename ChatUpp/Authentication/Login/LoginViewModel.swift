//
//  LoginViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class LoginViewModel: EmailValidator {
    
    //MARK: - Sign in with email
    
    var email: String = ""
    var password: String = ""
    
    var loginStatus: ObservableObject<LoginStatus?> = ObservableObject(nil)
    
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
    
    //MARK: - Sign in with google
    
    func googleSignIn() {
        let helper = SignInGoogleHelper()
        helper.signIn { signInResult in
            if let tokens = signInResult {
                AuthenticationManager.shared.signInWithGoogle(usingTokens: tokens) { [weak self] authResultModel in
                    if authResultModel != nil {
                        self?.loginStatus.value = .loggedIn
                    }
                }
            }
        }
    }
}
