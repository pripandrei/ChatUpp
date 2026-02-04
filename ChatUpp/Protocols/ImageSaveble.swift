////
////  Untitled.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 1/8/25.
////


import Foundation

// MARK: - ImageSampleHandling Protocol
protocol ImageSampleHandling: AnyObject
{
    var imageSampleRepository: ImageSampleRepository? { get set }
    var profilePhotoURL: String? { get set }
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
        CacheManager.shared.saveData(imageData, toPath: path)
    }
}
