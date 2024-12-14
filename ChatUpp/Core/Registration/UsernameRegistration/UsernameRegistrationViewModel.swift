//
//  UsernameRegistrationViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation
import Kingfisher

enum ValidationStatus {
    case valid
    case invalid
}

//MARK: - Username registration View Model
 
final class UsernameRegistrationViewModel
{
    private(set) var profileImageData: Data?
    private(set) var registrationCompleted: ObservableObject<Bool?> = ObservableObject(nil)
    private var profilePhotoURL: String?
    var username: String = ""
    
    func validateName() -> ValidationStatus {
        if !self.username.isEmpty {
            return .valid
        }
        return .invalid
    }
    
    private var authUser: AuthDataResultModel {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            return user
        }
        fatalError("user is missing")
    }
    
    private func saveProfileImageToStorage() async throws -> String?
    {
        if let profileImageData = profileImageData
        {
            let (_, name) = try await FirebaseStorageManager.shared.saveUserImage(data: profileImageData, userId: authUser.uid)
            return name
        }
        return nil
    }
    
    private func saveImageData() async throws
    {
        guard let data = self.profileImageData else { return }
        self.profilePhotoURL = try await saveProfileImageToStorage()
        CacheManager.shared.saveImageData(data, toPath: profilePhotoURL ?? "")
    }
    
    private func updateUser() async throws
    {
        try await FirestoreUserService.shared.updateUser(with: authUser.uid,
                                                         usingName: username,
                                                         profilePhotoURL: profilePhotoURL)
    }
    
    func finishRegistration()
    {
        Task {
            do {
                try await updateUser()
                try await saveImageData()
                self.registrationCompleted.value = true
            } catch {
                print("Error finishing registration: ", error.localizedDescription)
            }
        }
    }

    func updateUserProfileImage(_ data: Data?) {
        profileImageData = data
    }
}


class ImageCacheService
{
    static let shered = ImageCacheService()
    
    private init() {}
    
    func cacheImageData(_ data: Data, for key: String)
    {
        ImageCache.default.storeToDisk(data, forKey: key)
    }
}
