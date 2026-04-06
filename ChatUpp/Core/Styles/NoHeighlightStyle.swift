//
//  NoHeighlightButtonStyle.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/6/26.
//

import SwiftUI

struct NoHighlightStyle: ButtonStyle
{
    func makeBody(configuration: Configuration) -> some View
    {
        configuration.label
            .opacity(1)
    }
}
