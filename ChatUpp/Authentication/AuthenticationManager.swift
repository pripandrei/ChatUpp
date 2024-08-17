//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/5/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import GoogleSignIn


enum AuthenticationStatus: Error {
    case userIsAuthenticated
    case userIsNotAuthenticated
}

//MARK: - Authentication result model

struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    let name: String?
    let phoneNumber: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoURL = user.photoURL?.absoluteString
        self.name = user.displayName
        self.phoneNumber = user.phoneNumber
    }
}

//MARK: - Auth Manager

final class AuthenticationManager
{
    static var shared = AuthenticationManager()
    
    private init() {}
    
    @discardableResult
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        if let user = Auth.auth().currentUser {
            return AuthDataResultModel(user: user)
        }
        throw AuthenticationStatus.userIsNotAuthenticated
    }
    
    //TEMP function until local DB is not implemented
    
//    func updateAuthUserPhone(_ phone: String) {
//
//        Auth.auth().currentUser?.updatePhoneNumber(<#T##phoneNumberCredential: PhoneAuthCredential##PhoneAuthCredential#>)
//    }
    
    //TODO: implement phone update functionality
    func updateAuthUserData(name: String?, phoneNumber: String?, photoURL: String?) {
        let profile = Auth.auth().currentUser?.createProfileChangeRequest()
        profile?.displayName = name
        
        if let photoURL = photoURL {
            let url = URL(string: photoURL)
            profile?.photoURL = url
        }
        profile?.commitChanges()
    }
    
    func signOut() throws  {
        try Auth.auth().signOut()
    }
    
    func getAuthProvider() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else { return ""}
        let authToken = try await currentUser.getIDTokenResult(forcingRefresh: true)
        return authToken.signInProvider
    }
    
    // Email signin reauthenticate
    
    func emailAuthReauthenticate(with verificationID: String, verificationCode: String) async throws {
      /// implement
    }
    
    // Phone signin reauthenticate
    func phoneAuthReauthenticate(with verificationID: String, verificationCode: String) async throws {
        if let user = Auth.auth().currentUser {
            let phoneCredentials = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
            try await user.reauthenticate(with: phoneCredentials)
        }
    }
    
    // Google signin reauthenticate
    func googleAuthReauthenticate() async throws {
        if let user = Auth.auth().currentUser {
            let googleUser = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            let authentication = GoogleAuthProvider.credential(withIDToken: googleUser.idToken!.tokenString, accessToken: googleUser.accessToken.tokenString)
            try await user.reauthenticate(with: authentication)
        }
    }
}

//MARK: - Sign in with Email

extension AuthenticationManager {
    func signIn(email: String, password: String, complition: @escaping (AuthDataResultModel?) -> Void)  {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("Could not log you in. Error: \(String(describing: error))")
                complition(nil)
                return
            }
            let authDataResultModel = AuthDataResultModel(user: result.user)
            complition(authDataResultModel)
        }
    }
    
    func signUpUser(email: String, password: String, complition: @escaping ((AuthDataResultModel?) -> Void))  {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("There was an error during user registration: \(String(describing: error))")
                complition(nil)
                return
            }
            let authDataResultModel = AuthDataResultModel(user: result.user)
            complition(authDataResultModel)
        }
    }
}

//MARK: - SSO google

extension AuthenticationManager {
    
    func signInWithGoogle(usingTokens tokens: GoogleSignInResultModel, complition: @escaping (AuthDataResultModel?) -> Void) 
    {
        let credentials = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        
        googleSignin(credentials: credentials) { authResultModel in
            guard let authModel = authResultModel else {
                complition(nil)
                return
            }
            complition(authModel)
        }
    }
    
    private func googleSignin(credentials: AuthCredential, complition: @escaping (AuthDataResultModel?) -> Void)
    {
        Auth.auth().signIn(with: credentials) { authResult, error in
            guard let result = authResult, error == nil else {
                print("SSO error: \(error!.localizedDescription)")
                complition(nil)
                return
            }
//            result.user.
            let authDataModel = AuthDataResultModel(user: result.user)
            complition(authDataModel)
        }
    }
}

//MARK: - PHONE SMS AUTH

extension AuthenticationManager {
    
    func sendSMSToPhone(number: String) async throws -> String {
        try await PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil)
    }
    
    func createOTPCredentials(with verificationID: String, verificationCode: String) -> PhoneAuthCredential {
        return PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
    }
    
    func signinWithPhoneSMS(using verificationID:String, verificationCode: String) async throws -> AuthDataResultModel {
        let credentials = createOTPCredentials(with: verificationID, verificationCode: verificationCode)
        let result = try await Auth.auth().signIn(with: credentials)
        let authDataModel = AuthDataResultModel(user: result.user)
        return authDataModel
    }
}

//MARK: - Delete user
extension AuthenticationManager {
    func deleteAuthUser() async throws {
        guard let authUser = Auth.auth().currentUser else {return}
        try await authUser.delete()
    }
}
