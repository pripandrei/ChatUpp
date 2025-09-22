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

    private var tempTextField: UITextField?
    
    @objc class func keyboardHeight() -> CGFloat
    {
        let keyboardSize = KeyboardService.keyboardSize()
        return keyboardSize.size.height
    }

    @objc class func keyboardSize() -> CGRect
    {
        return shared.measuredSize
    }

    private func observeKeyboardNotifications()
    {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(self.keyboardChange),
                           name: UIResponder.keyboardWillShowNotification,
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

    @objc private func keyboardChange(_ notification: Notification)
    {
        guard measuredSize == CGRect.zero,
              let info = notification.userInfo,
              let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        
        measuredSize = value.cgRectValue
        tempTextField?.resignFirstResponder()
        tempTextField?.removeFromSuperview()
    }

    override init() {
        super.init()
        observeKeyboardNotifications()
        observeKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
