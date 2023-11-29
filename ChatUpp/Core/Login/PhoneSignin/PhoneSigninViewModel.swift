//
//  PhoneSigninViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

import Foundation


final class PhoneSignInViewModel {
    
    let loginStatus: ObservableObject<AuthenticationStatus?> = ObservableObject(nil)
    
    let verificationIDKey = "authVerificationID"
    
    let defaults = UserDefaults.standard
    
    lazy var verificationID = defaults.string(forKey: verificationIDKey)
    
    func signInViaPhone(usingVerificationID verificationID: String, verificationCode: String) {
        Task {
            do {
                let resultModel = try await AuthenticationManager.shared.signinWithPhoneSMS(using: verificationID, verificationCode: verificationCode)
                let dbUser = DBUser(auth: resultModel)
                UserManager.shared.createNewUser(user: dbUser) { [weak self] isCreated in
                    isCreated ? (self?.loginStatus.value = .userIsAuthenticated) : (self?.loginStatus.value = .userIsNotAuthenticated)
                }
            } catch {
                print("Error signing in with Phone: ", error.localizedDescription)
            }
        }
    }
    
    func sendSmsToPhoneNumber(_ number: String) {
        Task {
            do {
                let verificationID = try await AuthenticationManager.shared.sendSMSToPhone(number: number)
                defaults.set(verificationID, forKey: verificationIDKey)
            } catch {
                print("error sending sms to phone number: ", error.localizedDescription)
            }
        }
    }
    
}
