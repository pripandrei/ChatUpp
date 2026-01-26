//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/26/26.
//

import Foundation

@Observable
final class NicknameUpdateViewModel
{
    private(set) var nicknameValidationStatus: NicknameValidationResult
    private var initialNickname: String
    var updatedNickname: String

    init(updatedNickname: String)
    {
        self.initialNickname = updatedNickname
        self.updatedNickname = updatedNickname
        self.nicknameValidationStatus = .initial
    }
    
    func checkIfNicknameIsValid()
    {
        updateNicknameCuttingSpace()
        
        if updatedNickname.contains("__")
        {
            nicknameValidationStatus = .invalid
            return
        }
        
        if updatedNickname.count < 5
        {
            nicknameValidationStatus = .isShort
            return
        }
        
        if updatedNickname.count > 30
        {
            nicknameValidationStatus = .invalid
            return
        }
        
        if updatedNickname == initialNickname
        {
            nicknameValidationStatus = .initial
            return
        }
        
        Task {
            try await checkIfNicknameIsAvailable()
        }
    }
    
    private func checkIfNicknameIsAvailable() async throws
    {
        let exists = await AlgoliaSearchManager.shared.checkIfUserWithNicknameExists(updatedNickname)
        print(exists)

        self.nicknameValidationStatus = exists ? .isTaken : .isAvailable(name: self.updatedNickname)
    }
    
    private func updateNicknameCuttingSpace()
    {
        var updatedNickname: String = self.updatedNickname
    
        updatedNickname = updatedNickname.replacingOccurrences(of: " ", with: "_")
        
        if self.updatedNickname != updatedNickname
        {
            self.updatedNickname = updatedNickname
        }
    }
    
    @MainActor
    func saveNickname() async throws
    {
        guard let userID = AuthenticationManager.shared.authenticatedUser?.uid,
        let realmUser = RealmDatabase.shared.retrieveSingleObject(ofType: User.self,
                                                                  primaryKey: userID) else {return}

        RealmDatabase.shared.update(object: realmUser) { dbUser in
            dbUser.nickname = self.updatedNickname
        }
        
            try await FirestoreUserService.shared.updateUser(with: userID,
                                                             nickname: self.updatedNickname)
    }
}

extension NicknameUpdateViewModel
{
    enum NicknameValidationResult: Equatable, Hashable
    {
        case isAvailable(name: String)
        case isTaken
        case isShort
        case invalid
        case initial
        
        var statusTitle: String
        {
            switch self
            {
            case .isAvailable(let nickName): return "\(nickName) is available"
            case .isTaken: return "This nickname is already taken"
            case .isShort: return "Nickname must have at least 5 characters"
            case .invalid: return "Sorry, this nickname is invalid"
            default: return ""
            }
        }
        
        var isValid: Bool
        {
            switch self
            {
            case .isAvailable: return true
            default: return false
            }
        }
    }
}
