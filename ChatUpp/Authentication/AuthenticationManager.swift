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


enum AuthenticationStatus: Error {
    case userIsAuthenticated
    case userIsNotAuthenticated
}

//MARK: - Authentication result model

//ADD DATE CREATED!!
struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoURL: String?
    let name: String?
    let phoneNumber: String?
//    let phoneNumber: String?
    
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
//        let change = Auth.auth().currentUser?.createProfileChangeRequest()
//        change?.displayName = "Anatolii Andreevici"
//        change?.commitChanges()
        if let user = Auth.auth().currentUser {
            return AuthDataResultModel(user: user)
        }
        throw AuthenticationStatus.userIsNotAuthenticated
    }
    
    func signOut() throws  {
        try Auth.auth().signOut()
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
        print("Success Credentials!: ", credentials)
        return authDataModel
    }
    
}
