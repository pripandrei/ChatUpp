//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/23.
//

import Foundation
import UIKit


protocol EmailValidator
{
    var email: String { get set }
    var password: String { get set }
    func validateCredentials() throws
}

final class TextFieldValidator: NSObject, UITextFieldDelegate {
    
    var mail: UITextField!
    var pass: UITextField!
    
    var viewModel: EmailValidator!
    
    init(viewModel: EmailValidator) {
        self.viewModel = viewModel
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textFieldShouldSwitchSelection(textField)
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
    
    
    func validate() -> Bool {
        do {
            try viewModel.validateCredentials()
            return true
        } catch CredentialsError.emptyMail {
            mail.becomeFirstResponder()
            print("Mail is empty")
            return false
        } catch CredentialsError.empyPassword {
            pass.becomeFirstResponder()
            print("Password is empty")
            return false
        } catch CredentialsError.shortPassword  {
            print("Password must not be shorter than 6 character")
            return false
        } catch {
            print("Something went wrong validating credentials")
            return false
        }
    }

}
