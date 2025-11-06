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
    
    func requestCameraPermision() -> AnyPublisher<Bool, Never>
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
               completion(granted)
            }
        default:
            completion(false)
        }
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void)
    {
        if #available(iOS 17.0, *)
        {
            let status = AVAudioApplication.shared.recordPermission
            if status == .undetermined {
                AVAudioApplication.requestRecordPermission { allowed in
                    completion(allowed)
                }
            } else {
                return completion(status == .granted)
            }
        } else
        {
            let status = AVAudioSession.sharedInstance().recordPermission
            if status == .undetermined
            {
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    completion(allowed)
                }
            }
            else
            {
                return completion(status == .granted)
            }
        }
    }
//    
//    func requestMicrophonePermission() -> AnyPublisher<Bool, Never>
//    {
//        if #available(iOS 17.0, *)
//        {
//            let status = AVAudioApplication.shared.recordPermission
//            if status == .undetermined {
//                return Future { promise in
//                    AVAudioApplication.requestRecordPermission { allowed in
//                        promise(.success(allowed))
//                    }
//                }.eraseToAnyPublisher()
//            } else {
//                return Just(status == .granted).eraseToAnyPublisher()
//            }
//        } else
//        {
//            let status = AVAudioSession.sharedInstance().recordPermission
//            if status == .undetermined {
//                return Future { promise in
//                    AVAudioSession.sharedInstance().requestRecordPermission { allowed in
//                        promise(.success(allowed))
//                    }
//                }.eraseToAnyPublisher()
//            } else {
//                return Just(status == .granted).eraseToAnyPublisher()
//            }
//        }
//    }
//    
//    func requestMicrophonePermission2()
//    {
//        if #available(iOS 17.0, *)
//        {
//            AVAudioApplication.requestRecordPermission { allowed in
//                if allowed {
//                    print("audio rec allowed")
//                }
//                else {
//                    print("audio rec not allowed")
//                }
//            }
//        }
//        else
//        {
//            AVAudioSession.sharedInstance().requestRecordPermission { granted in
//                if granted {
//                    print("mic access granted")
//                }
//                else {
//                    print("mic access denied")
//                }
//            }
//        }
//    }
    
    func isCameraAvailable() -> Bool
    {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}


enum PermissionsError: Error
{
    case cameraDenied
    case microphoneDenied
    case photoLibraryDenied
}

enum PermissionType
{
    case camera
    case microphone
    case photoLibrary
}

