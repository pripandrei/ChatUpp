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
    private(set) var registrationCompleted: ObservableObject<Bool?> = ObservableObject(nil)
    private var profilePhotoURL: String?
    var username: String = ""
    
    private(set) var imageSampleRepository: ImageSampleRepository?
    {
        didSet {
            profilePhotoURL = imageSampleRepository?.imagePath(for: .original)
        }
    }
    
    private var authUser: AuthDataResultModel {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            return user
        }
        fatalError("user is missing")
    }
    
    func validateName() -> ValidationStatus {
        return username.isEmpty ? .invalid : .valid
    }
    
    func setImageSampleRepository(_ sampleRepository: ImageSampleRepository) {
        self.imageSampleRepository = sampleRepository
    }
 
    private func saveImageDataToFirebase(_ data: Data, path: String) async throws
    {
        let imageMetadata = try await FirebaseStorageManager.shared.saveImage(
            data: data,
            to: .user(authUser.uid),
            imagePath: path
        )
    }
    
    private func processImageSamples() async throws
    {
        guard let sampleRepository = imageSampleRepository else { return }
        
        for (key, imageData) in sampleRepository.samples
        {
            let path = sampleRepository.imagePath(for: key)
            try await saveImageDataToFirebase(imageData, path: path)
            CacheManager.shared.saveImageData(imageData, toPath: path)
        }
    }

    private func updateUser() async throws
    {
        try await FirestoreUserService.shared.updateUser(with: authUser.uid,
                                                         usingName: username,
                                                         profilePhotoURL: profilePhotoURL)
    }
    
    @MainActor
    private func addUserToRealmDB()
    {
        let user = User(userId: authUser.uid,
                        name: username,
                        email: authUser.email,
                        photoUrl: profilePhotoURL,
                        phoneNumber: authUser.phoneNumber,
                        nickName: nil,
                        dateCreated: Date(),
                        lastSeen: Date(),
                        isActive: true)
        
        print("User ID: ",user.id)
        
        RealmDataBase.shared.add(object: user)
    }
    
    func finishRegistration()
    {
        Task {
            do {
                try await processImageSamples()
                try await updateUser()
                await self.addUserToRealmDB()
                self.registrationCompleted.value = true
            } catch {
                print("Error finishing registration: ", error.localizedDescription)
            }
        }
    }
}
