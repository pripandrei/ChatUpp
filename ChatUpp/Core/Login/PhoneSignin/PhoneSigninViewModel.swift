//
//  PhoneSigninViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

import Foundation


final class PhoneSignInViewModel {
    
    let verificationIDKey = "authVerificationID"
    
    let defaults = UserDefaults.standard
    lazy var verificationID = defaults.string(forKey: verificationIDKey)
    
    let loginStatus: ObservableObject<AuthenticationStatus?> = ObservableObject(nil)
    
    func signInViaPhone(usingVerificationCode code: String) {
        guard let verificationID = verificationID else { print("missing verificationID"); return}
        Task {
            do {
                let resultModel = try await AuthenticationManager.shared.signinWithPhoneSMS(using: verificationID, verificationCode: code)
                let dbUser = DBUser(auth: resultModel)
                UserManager.shared.createNewUser(user: dbUser) { [weak self] isCreated in
                    isCreated ? (self?.loginStatus.value = .userIsAuthenticated) : (self?.loginStatus.value = .userIsNotAuthenticated)
                }
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
