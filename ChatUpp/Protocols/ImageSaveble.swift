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
