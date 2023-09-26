//
//  SignInGoogleHelper.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import GoogleSignIn

struct SignInGoogleHelper {
    
    func signIn(complition: @escaping (GoogleSignInResultModel?) -> Void)
    {
        guard let loginVC = Utilities.findLoginViewControllerInHierarchy() else {
            print("Could not find loginVC in hierarcy")
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: loginVC) { GIDSignInResult, error in
            guard error == nil else {
                complition(nil)
                print(error!.localizedDescription)
                return
            }
            guard let result = GIDSignInResult , let idToken = result.user.idToken?.tokenString else {
                complition(nil)
                print("Error getting user token")
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
            complition(tokens)
        }
    }
}
