////
////  Untitled.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 1/8/25.
////
//
//import Foundation
//
//protocol ImageSaveble
//{
//    func processImageSamples() async throws
//    func saveImageDataToFirebase(_ data: Data,
//                                 storageChildObject: StorageChildObject) async throws
//}
//
//extension ImageSaveble
//{
//    func processImageSamples(from sampleRepository: ImageSampleRepository?) async throws
//    {
//        guard let sampleRepository = sampleRepository else { return }
//        
//        for (key, imageData) in sampleRepository.samples {
//            let path = sampleRepository.imagePath(for: key)
//            try await saveImageDataToFirebase(imageData, path: path)
//            CacheManager.shared.saveImageData(imageData, toPath: path)
//        }
//    }
//
////    func saveImageDataToFirebase(_ data: Data,
////                                         storageChildObject: StorageChildObject) async throws
////    {
////        let (_, _) = try await FirebaseStorageManager.shared.saveImage(data: data, storageChildObject: storageChildObject)
////    }
//}
//
//
//struct ImageProcessor: ImageSaveble
//{
//    var storageChildObject: StorageChildObject
//    
//    func processImageSamples() async throws {
//        <#code#>
//    }
//    
//    func saveImageDataToFirebase(_ data: Data,
//                                         storageChildObject: StorageChildObject) async throws
//    {
//        let (_, _) = try await FirebaseStorageManager.shared.saveImage(data: data, storageChildObject: storageChildObject)
//    }
//}


import Foundation

// MARK: - ImageSampleHandling Protocol
protocol ImageSampleHandling: AnyObject {
    var imageSampleRepository: ImageSampleRepository? { get set }
    var profilePhotoURL: String? { get set }
    
    // Required property that conforming types must implement
    var userId: String { get }
}

// MARK: - Default Implementation
extension ImageSampleHandling
{
    func setImageSampleRepository(_ sampleRepository: ImageSampleRepository) {
        imageSampleRepository = sampleRepository
        profilePhotoURL = sampleRepository.imagePath(for: .original)
    }
    
    func processImageSamples() async throws {
        guard let sampleRepository = imageSampleRepository else { return }
        
        for (key, imageData) in sampleRepository.samples {
            let path = sampleRepository.imagePath(for: key)
            try await saveImage(imageData, path: path)
        }
    }
    
    private func saveImage(_ imageData: Data, path: String) async throws {
        let _ = try await FirebaseStorageManager.shared.saveImage(
            data: imageData,
            to: .user(userId),
            imagePath: path
        )
        CacheManager.shared.saveImageData(imageData, toPath: path)
    }
}
