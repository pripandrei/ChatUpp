//
//  File.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/22/23.
//

import Foundation
import UIKit

enum CredentialsError: Error {
    case emptyMail
    case empyPassword
    case shortPassword
}

protocol EmailValidator
{
    var email: String { get set }
    var password: String { get set }
    func validateEmailCredentials() throws
}

extension EmailValidator
{
    func validateEmailCredentials() throws {
        guard !email.isEmpty else {
            throw CredentialsError.emptyMail
        }
        guard !password.isEmpty else {
            throw CredentialsError.empyPassword
        }
        guard password.count > 6 else {
            throw CredentialsError.shortPassword
        }
    }
}

final class CredentialsValidator: NSObject {
    
    var mail: UITextField
    var pass: UITextField
    
    var validator: EmailValidator
    
    init(mailField: UITextField, passwordField: UITextField, validator: EmailValidator) {
        self.validator = validator
        self.mail = mailField
        self.pass = passwordField
        self.pass.isSecureTextEntry = true
    }
}

// MARK: - Text Field Delegate

extension CredentialsValidator: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textFieldShouldSwitchSelection(textField)
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            switch textField {
            case mail: validator.email = text
            case pass: validator.password = text
            default: break
            }
        }
    }
    
    // Custom function
    private func textFieldShouldSwitchSelection(_ textField: UITextField) -> Bool
    {
        if textField == mail,
           let mailText = textField.text, !mailText.isEmpty,
           let passwordText = pass.text, passwordText.isEmpty
        {
            return pass.becomeFirstResponder()
        }
        return textField.resignFirstResponder()
    }
}

// MARK: - Validation

extension CredentialsValidator
{
    func validate() -> Bool {
        do {
            try validator.validateEmailCredentials()
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


