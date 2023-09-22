//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/23.
//

import Foundation
import UIKit


protocol ViewModelFieldsValidator
{
    var email: String { get set }
    var password: String { get set }
    func validateCredentials() throws
}

final class TextFieldValidator: NSObject, UITextFieldDelegate {
    
    var mail: UITextField!
    var pass: UITextField!
    
    var viewModel: ViewModelFieldsValidator!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("return")
        return textFieldShouldSwitchSelection(textField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("begin")
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            switch textField {
            case mail: viewModel.email = text
            case pass: viewModel.password = text
            default: break
            }
        }
    }

    private func textFieldShouldSwitchSelection(_ textField: UITextField) -> Bool {
        if textField == mail, let mailText = textField.text, !mailText.isEmpty,
           let passwordText = pass.text, passwordText.isEmpty {
            return pass.becomeFirstResponder()
        }
        return textField.resignFirstResponder()
    }
}
