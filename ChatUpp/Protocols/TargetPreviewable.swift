//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/12/25.
//

import YYText
import UIKit

protocol TargetPreviewable: UIView
{
    var cellViewModel: MessageCellViewModel! { get }
    var contentContainer: UIView! { get }
}
