//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/26/26.
//

import Foundation
import Combine

@Observable
final class NicknameUpdateViewModel
{
    private(set) var nicknameValidationStatus: NicknameValidationResult
    private var initialNickname: String
    var updatedNickname: String
    
    private var subscribers: Set<AnyCancellable> = []
 
    init(updatedNickname: String)
    {
        self.initialNickname = updatedNickname
        self.updatedNickname = updatedNickname
        self.nicknameValidationStatus = .initial
//        addUpdatedNicknamSubscriber()
    }
    
//    private func addUpdatedNicknamSubscriber()
//    {
//        $updatedNickname
//            .debounce(for: 0.3, scheduler: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.checkIfNicknameIsValid()
//            }.store(in: &subscribers)
//    }
    
//    private func addUpdatedNicknamSubscriber()
//    {
//        $updatedNickname
//            .debounce(for: 0.3, scheduler: DispatchQueue.main)
//            .flatMap { output in
//                Future<NicknameValidationResult, Never> { promise in
//                    Task
//                    {
//                        let status = await self.checkIfNicknameIsValid()
//                        promise(.success(status))
//                    }
//                }
//            }
//            .sink { [weak self] value in
//                self?.nicknameValidationStatus = value
//            }
//            .store(in: &subscribers)
//    }
    
//    func checkIfNicknameIsValid() async -> NicknameValidationResult
//    {
//        updateNicknameCuttingSpace()
//        
//        if updatedNickname.contains("__")
//        {
//            return .invalid
//        }
//        
//        if updatedNickname.count < 5
//        {
//            return .isShort
//        }
//        
//        if updatedNickname.count > 30
//        {
//            return .invalid
//        }
//        
//        if updatedNickname == initialNickname
//        {
//            return .initial
//        }
//        
//        let exists = await AlgoliaSearchManager.shared.checkIfUserWithNicknameExists(updatedNickname)
//        return exists ? .isTaken : .isAvailable(name: self.updatedNickname)
//    }
    
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
           self.nicknameValidationStatus = try await checkIfNicknameIsAvailable()
        }
    }
    
    private func checkIfNicknameIsAvailable() async throws -> NicknameValidationResult
    {
        let exists = await AlgoliaSearchManager.shared.checkIfUserWithNicknameExists(updatedNickname)
        print(exists)

        return exists ? .isTaken : .isAvailable(name: self.updatedNickname)
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
