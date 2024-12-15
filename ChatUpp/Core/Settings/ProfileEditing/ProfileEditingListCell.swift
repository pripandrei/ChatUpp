//
//  ProfileEditingListCell.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/15/24.
//

import UIKit

//MARK: - CUSTOM LIST CELL
class ProfileEditingListCell: UICollectionViewListCell, UITextFieldDelegate
{
    var textField: UITextField!
    
    var onTextChanged: ((String) -> Void)?
    
    override func updateConfiguration(using state: UICellConfigurationState)
    {
        var newConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
        let customColor = #colorLiteral(red: 0.1057919934, green: 0.2902272344, blue: 0.4154375792, alpha: 1).withAlphaComponent(0.5)
        newConfiguration.backgroundColor = customColor
        backgroundConfiguration = newConfiguration
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        textField = makeTextField()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeTextField() -> UITextField
    {
        let textfield = UITextField(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.bounds.width, height: self.bounds.height)))
        textfield.delegate = self
        textfield.textColor = .black
        textfield.layer.sublayerTransform = CATransform3DMakeTranslation(20, 0, 0)
        self.contentView.addSubview(textfield)

        return textfield
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        if let text = textField.text as NSString?
        {
            let updatedText = text.replacingCharacters(in: range, with: string)
            onTextChanged?(updatedText as String)
        }
        return true
    }
}
