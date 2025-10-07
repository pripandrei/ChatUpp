//
//  AlertPresenter.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/11/25.
//

import UIKit
import Combine

final class AlertPresenter
{
    func presentImageSourceOptions(from presenter: UIViewController,
                                   cameraAvailable: Bool,
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
        
        if cameraAvailable {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in onCamera() })
        }
        alert.addAction(UIAlertAction(title: "Gallery", style: .default) { _ in onGallery() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        presenter.present(alert, animated: true)
    }
    
    func presentPermissionDeniedAlert(from presenter: UIViewController)
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
        presenter.present(alert, animated: true)
    }
    
    func presentDeletionAlert(from presenter: UIViewController,
                              using viewModel: ChatCellViewModel,
                              initiateDeletion: @escaping (ChatDeletionOption) -> Void)
    {
        let vm = viewModel
        let participantName = vm.chatUser?.name
        let alertTitle = vm.chat.isGroup ? "Are you sure you want to leave \(vm.chat.name ?? "unknown")?" : "Permanently delete chat with \(participantName ?? "User")?"
        let alertTitleAttributes: [NSAttributedString.Key:Any] = [
            .foregroundColor: #colorLiteral(red: 0.7950155139, green: 0.7501099706, blue: 0.7651557922, alpha: 1),
            .font: UIFont.systemFont(ofSize: 19),
        ]
        
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
    
        alert.setValue(NSAttributedString(string: alertTitle,
                                          attributes: alertTitleAttributes),
                       forKey: "attributedTitle")
        
        if vm.chat.isGroup
        {
            alert.addAction(UIAlertAction(title: "Leave the group", style: .destructive, handler: { action in
                initiateDeletion(.leaveGroup)
//                self?.initiateChatDeletion(at: indexPath, deleteOption: .leaveGroup)
            }))
            
        } else {
            alert.addAction(UIAlertAction(title: "Delete just for me", style: .destructive) { action in
                initiateDeletion(.forMe)
//                self?.initiateChatDeletion(at: indexPath, deleteOption: .forMe)
                print("deleted just for me!!!")
            })
            
            alert.addAction(UIAlertAction(title: "Delete for me and \(participantName ?? "User")", style: .destructive) { action in
                initiateDeletion(.forBoth)
//                self?.initiateChatDeletion(at: indexPath, deleteOption: .forBoth)
                print("deleted for both!!!")
            })
        }
    
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
       
//        mainQueue {
//            alert.setBackgroundColor(color: ColorManager.navigationBarBackgroundColor)
//        }
        
        presenter.present(alert, animated: true)
    }
}
