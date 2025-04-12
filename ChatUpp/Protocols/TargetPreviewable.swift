//
//  Untitled.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/12/25.
//

import YYText
import UIKit

protocol TargetPreviewable
{
    func getTargetViewForPreview() -> UIView
    func getTargetedPreviewColor() -> UIColor
}
