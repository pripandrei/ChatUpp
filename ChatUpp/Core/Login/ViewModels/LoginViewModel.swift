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
    
    var loginStatus: ObservableObject<AuthenticationStatus?> = ObservableObject(nil)
}

//MARK: - Sign in with email

extension LoginViewModel: EmailValidator
{
    func signInWithEmail()
    {
        AuthenticationManager.shared.signIn(email: email, password: password) { [weak self] authRestult in
            guard let _ = authRestult else {
                return
            }
            self?.loginStatus.value = .userIsAuthenticated
        }
    }
}

//MARK: - Sign in with google
    
extension LoginViewModel
{
    func googleSignIn()
    {
        let helper = SignInGoogleHelper()
        
        helper.signIn { [weak self] signInResult in
            guard let tokens = signInResult else {
                return
            }
            AuthenticationManager.shared.signInWithGoogle(usingTokens: tokens) { [weak self] authResultModel in
                guard let authResultModel = authResultModel else {
                    return
                }
                
                let dbUser = User(auth: authResultModel)
                FirestoreUserService.shared.createNewUser(user: dbUser) { [weak self] isCreated in
                   isCreated ? (self?.loginStatus.value = .userIsAuthenticated) : nil
                }
                RealtimeUserService.shared.createUser(user: dbUser)
            }
        }
    }
}

