//
//  IndexPath+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/13/25.
//

import Foundation

extension IndexPath
{
    func isFirst() -> Bool
    {
        return self.row == 0 && self.section == 0
    }
}
