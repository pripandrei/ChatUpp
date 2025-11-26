//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/5/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn


enum AuthenticationStatus: Error {
    case userIsAuthenticated
    case userIsNotAuthenticated
}

//MARK: - Authentication result model

struct AuthenticatedUserData {
    let uid: String
    let email: String?
    let photoURL: String?
    let name: String?
    let phoneNumber: String?
    
    init(firebaseAuthUser: FirebaseAuth.User) {
        self.uid = firebaseAuthUser.uid
        self.email = firebaseAuthUser.email
        self.photoURL = firebaseAuthUser.photoURL?.absoluteString
        self.name = firebaseAuthUser.displayName
        self.phoneNumber = firebaseAuthUser.phoneNumber
    }
}

//MARK: - Auth Manager

final class AuthenticationManager
{
    static var shared = AuthenticationManager()
    
    private init() {}
    
    var authenticatedUser: AuthenticatedUserData?
    {
        if let user = Auth.auth().currentUser {
            return AuthenticatedUserData(firebaseAuthUser: user)
        }
        return nil
    }
    
    @discardableResult
    func getAuthenticatedUser() throws -> AuthenticatedUserData
    {
        if let user = Auth.auth().currentUser {
            return AuthenticatedUserData(firebaseAuthUser: user)
        }
        throw AuthenticationStatus.userIsNotAuthenticated
    }

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

extension AuthenticationManager
{
    func signIn(email: String, password: String, complition: @escaping (AuthenticatedUserData?) -> Void)  {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("Could not log you in. Error: \(String(describing: error))")
                complition(nil)
                return
            }
            let authDataResultModel = AuthenticatedUserData(firebaseAuthUser: result.user)
            complition(authDataResultModel)
        }
    }
    
    func signUpUser(email: String, password: String, complition: @escaping ((AuthenticatedUserData?) -> Void))
    {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard let result = authResult, error == nil else {
                print("There was an error during user registration: \(String(describing: error))")
                complition(nil)
                return
            }
            let authDataResultModel = AuthenticatedUserData(firebaseAuthUser: result.user)
            complition(authDataResultModel)
        }
    }
}

//MARK: - SSO google

extension AuthenticationManager {
    
    func signInWithGoogle(usingTokens tokens: GoogleSignInResultModel, complition: @escaping (AuthenticatedUserData?) -> Void) 
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
    
    private func googleSignin(credentials: AuthCredential, complition: @escaping (AuthenticatedUserData?) -> Void)
    {
        Auth.auth().signIn(with: credentials) { authResult, error in
            guard let result = authResult, error == nil else {
                print("SSO error: \(error!.localizedDescription)")
                complition(nil)
                return
            }
//            result.user.
            let authDataModel = AuthenticatedUserData(firebaseAuthUser: result.user)
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
    
    func signinWithPhoneSMS(using verificationID:String, verificationCode: String) async throws -> AuthenticatedUserData
    {
        let credentials = createOTPCredentials(with: verificationID, verificationCode: verificationCode)
        let result = try await Auth.auth().signIn(with: credentials)
        let authDataModel = AuthenticatedUserData(firebaseAuthUser: result.user)
        return authDataModel
    }
}

//MARK: - Delete user
extension AuthenticationManager
{
    func deleteAuthUser() async throws {
        guard let authUser = Auth.auth().currentUser else {return}
        try await authUser.delete()
    }
}
