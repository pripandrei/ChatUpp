//
//  PhoneSigninViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/28/23.
//

// +15655555300 Test Phone

import Foundation

enum UserCreationStatus {
    case userExists
    case userIsCreated
}

final class PhoneSignInViewModel {
    
    let verificationIDKey = "authVerificationID"
    
    let defaults = UserDefaults.standard
    lazy var verificationID = defaults.string(forKey: verificationIDKey)
    
    let userCreationStatus: ObservableObject<UserCreationStatus?> = ObservableObject(nil)
    
    func signInViaPhone(usingVerificationCode code: String) {
        guard let verificationID = verificationID else { print("missing verificationID"); return}
        Task {
            do {
                let resultModel = try await AuthenticationManager.shared.signinWithPhoneSMS(using: verificationID, verificationCode: code)
                let dbUser = User(auth: resultModel)
                if let _ = try? await UserManager.shared.getUserFromDB(userID: dbUser.id) {
                    userCreationStatus.value = .userExists
                } else {
                    try UserManager.shared.createNewUser(user: dbUser)
                    UserManagerRealtimeDB.shared.createUser(user: dbUser)
                    userCreationStatus.value = .userIsCreated
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
}
