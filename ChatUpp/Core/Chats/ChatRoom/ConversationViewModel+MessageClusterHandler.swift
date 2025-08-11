////
////  ConversationViewModel+MessageClusterHandler.swift
////  ChatUpp
////
////  Created by Andrei Pripa on 1/16/25.
////
//
//import Foundation
//import Combine
//
//// MARK: - messageCluster functions
//extension ConversationViewModel
//{
//    private func createMessageClustersWith(_ messages: [Message], ascending: Bool? = nil)
//    {
//        var dateToIndex = Dictionary(uniqueKeysWithValues: self.messageClusters.enumerated().map { ($0.element.date, $0.offset) })
//        var tempMessageClusters = self.messageClusters
//
//        messages.forEach { message in
//            guard let date = message.timestamp.formatToYearMonthDay() else { return }
//            let messageItem = MessageItem(message: message)
//
//            if let index = dateToIndex[date] {
//                ascending == true
//                    ? tempMessageClusters[index].items.insert(messageItem, at: 0)
//                    : tempMessageClusters[index].items.append(messageItem)
//            } else {
//                let newCluster = MessageCluster(date: date, items: [messageItem])
//                if ascending == true {
//                    tempMessageClusters.insert(newCluster, at: 0)
//                    dateToIndex[date] = 0
//                } else {
//                    tempMessageClusters.append(newCluster)
//                    dateToIndex[date] = tempMessageClusters.count - 1
//                }
//            }
//        }
//        self.messageClusters = tempMessageClusters
//    }
//
//    @MainActor
//    private func prepareMessageClustersUpdate(withMessages messages: [Message], inAscendingOrder: Bool) async throws -> ([IndexPath], IndexSet?)
//    {
//        let messageClustersBeforeUpdate = messageClusters
//        let startSectionCount = inAscendingOrder ? 0 : messageClusters.count
//        
//        createMessageClustersWith(messages, ascending: inAscendingOrder)
//        
//        let endSectionCount = inAscendingOrder ? (messageClusters.count - messageClustersBeforeUpdate.count) : messageClusters.count
//        
//        let newRows = findNewRowIndexPaths(inMessageClusters: messageClustersBeforeUpdate, ascending: inAscendingOrder)
//        let newSections = findNewSectionIndexSet(startSectionCount: startSectionCount, endSectionCount: endSectionCount)
//        
//        return (newRows, newSections)
//    }
//    
//    @MainActor
//    func handleAdditionalMessageClusterUpdate(inAscendingOrder order: Bool) async throws -> ([IndexPath], IndexSet?)? {
//        
//        let newMessages = try await loadAdditionalMessages(inAscendingOrder: order)
//        guard !newMessages.isEmpty else { return nil }
//        
//        let (newRows, newSections) = try await prepareMessageClustersUpdate(withMessages: newMessages, inAscendingOrder: order)
//        
//        if let timestamp = newMessages.first?.timestamp
//        {
//            messageListenerService.addListenerToExistingMessages(startAtTimestamp: timestamp, ascending: order)
//        }
//        realmService.addMessagesToConversationInRealm(newMessages)
//        
//        return (newRows, newSections)
//    }
//    
//    private func findNewRowIndexPaths(inMessageClusters messageClusters: [MessageCluster], ascending: Bool) -> [IndexPath]
//    {
//        guard let sectionBeforeUpdate = ascending ? messageClusters.first?.items : messageClusters.last?.items else {return []}
//        
//        let sectionIndex = ascending ? 0 : messageClusters.count - 1
//        
//        return self.messageClusters[sectionIndex].items
//            .enumerated()
//            .compactMap { index, viewModel in
//                return sectionBeforeUpdate.contains { $0.message == viewModel.message }
//                ? nil
//                : IndexPath(row: index, section: sectionIndex)
//            }
//    }
//    
//    private func findNewSectionIndexSet(startSectionCount: Int, endSectionCount: Int) -> IndexSet?
//    {
//        return (startSectionCount < endSectionCount)
//        ? IndexSet(integersIn: startSectionCount..<endSectionCount)
//        : nil
//    }
//}

import UIKit
import AVFoundation
import Combine

final class AlertPresenter
{
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController?) {
        self.viewController = viewController
    }
    
    func presentImageSourceOptions(cameraAvailable: Bool,
                                   onCamera: @escaping () -> Void,
                                   onGallery: @escaping () -> Void)
    {
        let alert = UIAlertController(title: "Choose image source",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .medium)
        ]
        alert.setValue(NSAttributedString(string: "Choose image source", attributes: titleAttributes),
                       forKey: "attributedTitle")
//        mainQueue {
//            alert.setBackgroundColor(color: ColorManager.navigationBarBackgroundColor)
//        }
        
        if cameraAvailable {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in onCamera() })
        }
        alert.addAction(UIAlertAction(title: "Gallery", style: .default) { _ in onGallery() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController?.present(alert, animated: true)
    }
    
    func presentPermissionDeniedAlert()
    {
        let alert = UIAlertController(title: "Permission Denied",
                                      message: "Please allow camera permission in settings to use camera feature.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsUrl) else { return }
            UIApplication.shared.open(settingsUrl)
        })
        viewController?.present(alert, animated: true)
    }
}


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
