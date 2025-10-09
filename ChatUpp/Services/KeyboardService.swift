//
//  KeyboardService.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/17/25.
//

import UIKit


//MARK: - See FootNote.swift - [15]
class KeyboardService: NSObject
{
    static var shared = KeyboardService()
    
    var measuredSize: CGRect = CGRect.zero
    var isKeyboardVisible: Bool = false

    private var tempTextField: UITextField?
    
    var keyboardHeight: CGFloat
    {
        return measuredSize.size.height
    }

    private func observeKeyboardNotifications()
    {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(self.keyboardDidShow),
                           name: UIResponder.keyboardWillShowNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(self.keyboardDidHidde),
                           name: UIResponder.keyboardDidHideNotification,
                           object: nil)
    }

    private func observeKeyboard()
    {
        self.tempTextField = UITextField()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first
        {
            window.addSubview(tempTextField!)
        }
        tempTextField?.becomeFirstResponder()
    }
    
    @objc private func keyboardDidHidde(_ notification: Notification)
    {
        self.isKeyboardVisible = false
    }

    @objc private func keyboardDidShow(_ notification: Notification)
    {
        self.isKeyboardVisible = true
        
        guard measuredSize == CGRect.zero,
              let info = notification.userInfo,
              let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        
        measuredSize = value.cgRectValue
        tempTextField?.resignFirstResponder()
        tempTextField?.removeFromSuperview()
        tempTextField = nil
    }

    override init()
    {
        super.init()
        observeKeyboardNotifications()
        observeKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
