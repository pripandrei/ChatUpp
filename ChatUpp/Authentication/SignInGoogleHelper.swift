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
                print(error!.localizedDescription)
                complition(nil)
                return
            }
            guard let result = GIDSignInResult , let idToken = result.user.idToken?.tokenString else {
                print("Error getting user token")
                complition(nil)
                return
            }
            let accessToken = result.user.accessToken.tokenString
            let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
            complition(tokens)
        }
    }
}


struct GoogleSignInResultModel {
    let idToken :String
    let accessToken :String
}
