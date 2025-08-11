//
//  PermissionManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/11/25.
//
import UIKit
import AVFoundation
import Combine

final class PermissionManager
{
    static let shared = PermissionManager()
    
    private init() {}
    
    func requestCameraPermision() -> AnyPublisher<Bool,Never>
    {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return Just(true).eraseToAnyPublisher()
        case .notDetermined:
            return Future<Bool, Never> { promise in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    promise(.success(granted))
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        default:
            return Just(true).eraseToAnyPublisher()
        }
    }
    
    func requestCameraPermision(completion: @escaping (Bool) -> Void)
    {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
               completion(true)
            }
        default:
            completion(true)
        }
    }
    
    func isCameraAvailable() -> Bool
    {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}

