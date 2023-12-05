//
//  PhoneSigninViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

import Foundation

enum UserCreationStatus: Error {

    case userExists
    case userIsCreated
//    case errorCreatingUser(Error)
}

final class PhoneSignInViewModel {
    
    let verificationIDKey = "authVerificationID"
    
    let defaults = UserDefaults.standard
    lazy var verificationID = defaults.string(forKey: verificationIDKey)
    
//    let signinStatus: ObservableObject<AuthenticationStatus?> = ObservableObject(nil)
    
    let signinStatus: ObservableObject<UserCreationStatus?> = ObservableObject(nil)
    
    func signInViaPhone(usingVerificationCode code: String) {
        guard let verificationID = verificationID else { print("missing verificationID"); return}
        Task {
            do {
                let resultModel = try await AuthenticationManager.shared.signinWithPhoneSMS(using: verificationID, verificationCode: code)
                let dbUser = DBUser(auth: resultModel)
                if let user = try? await UserManager.shared.getUserFromDB(userID: dbUser.userId) {
                    signinStatus.value = .userExists
                } else {
                    try await UserManager.shared.createNewUser2(user: dbUser)
                    signinStatus.value = .userIsCreated
                }
            
//                UserManager.shared.
                
//                UserManager.shared.createNewUser(user: dbUser) { [weak self] isCreated in
//                    isCreated ? (self?.signinStatus.value = .userIsAuthenticated) : (self?.signinStatus.value = .userIsNotAuthenticated)
//                }
            } catch {
                print("Error signing in with Phone: ", error.localizedDescription)
            }
        }
    }
    
    func sendSmsToPhoneNumber(_ number: String) async throws {
        let verificationID = try await AuthenticationManager.shared.sendSMSToPhone(number: number)
        defaults.set(verificationID, forKey: verificationIDKey)
    }
    
    
    //    func sendSmsToPhoneNumber(_ number: String) {
    //        Task {
    //            do {
    //                let verificationID = try await AuthenticationManager.shared.sendSMSToPhone(number: number)
    //                defaults.set(verificationID, forKey: verificationIDKey)
    //            } catch {
    //                print("error sending sms to phone number: ", error.localizedDescription)
    //            }
    //        }
    //    }
}
