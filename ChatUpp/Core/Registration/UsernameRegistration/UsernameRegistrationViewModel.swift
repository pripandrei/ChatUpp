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
    
    private(set) var imageSampleRepository: ImageSampleRepository?
    {
        didSet {
            profilePhotoURL = imageSampleRepository?.imagePath(for: .original)
        }
    }
    
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
    
    deinit {
        print("usernam view model wass deinit")
    }
    
    
//    private func saveProfileImageToStorage() async throws -> String?
//    {
//        if let profileImageData = profileImageData
//        {
//            let (_, name) = try await FirebaseStorageManager.shared.saveUserImage(data: profileImageData, userId: authUser.uid)
//            return name
//        }
//        return nil
//    }
    
//    private func saveProfileImageToStorage() async throws
//    {
//        guard let imageRepository = imageSampleRepository else {return}
//        for imageSample in imageRepository.samples
//        {
//            guard let path = imageSampleRepository?.imagePath(for: imageSample.key) else {continue}
//            
//            let (_, name) = try await FirebaseStorageManager.shared.saveUserImage(
//                data: imageSample.value,
//                userId: authUser.uid,
//                path: path
//            )
//            
//            if imageSample.key == .original {
//                profilePhotoURL = name
//            }
//        }
//    }
    
//    private func cacheImageData()
 //    {
 //        guard let imageRepository = imageSampleRepository else {return }
 //        for imageSample in imageRepository.samples {
 //            guard var path = profilePhotoURL else {return}
 //            path = path + "_\(imageSample.key.rawValue).jpg"
 //            CacheManager.shared.saveImageData(imageSample.value, toPath: profilePhotoURL ?? "")
 //        }
 //    }
 //
    
    private func saveImageDataToFirebaseStorage(_ data: Data, path: String) async throws
    {
        let (_, name) = try await FirebaseStorageManager.shared.saveUserImage(
            data: data,
            userId: authUser.uid,
            path: path
        )
    }
    
    private func saveImageData() async throws
    {
        guard let sampleRepository = self.imageSampleRepository else { return }
        
        for imageSample in sampleRepository.samples
        {
            guard let path = imageSampleRepository?.imagePath(for: imageSample.key) else {continue}
            
            try await saveImageDataToFirebaseStorage(imageSample.value, path: path)
            
            CacheManager.shared.saveImageData(imageSample.value, toPath: path)
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
                try await saveImageData()
                try await updateUser()
                await self.addUserToRealmDB()
                self.registrationCompleted.value = true
            } catch {
                print("Error finishing registration: ", error.localizedDescription)
            }
        }
    }

//    func updateUserProfileImage(_ data: Data?) {
//        profileImageData = data
//    }
    
    func setImageSampleRepository(_ sampleRepository: ImageSampleRepository) {
        self.imageSampleRepository = sampleRepository
    }
}
