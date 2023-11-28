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
    
    func sendSmsToPhoneNumber(_ number: String) {
        Task {
            do {
                let verificationID = try await AuthenticationManager.shared.sendSMSToPhone(number: number)
                defaults.set(verificationID, forKey: verificationIDKey)
            } catch {
                print("error sending sms to phone number: ", error)
            }
        }
    }
    
}
