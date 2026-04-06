//
//  GlassCapsuleButton.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 4/6/26.
//

import SwiftUI

@available(iOS 26.0, *)
struct GlassCapsuleStyle: ButtonStyle
{
    func makeBody(configuration: Configuration) -> some View
    {
        configuration.label
            .fixedSize()
            .padding(11)
            .contentShape(.capsule)
            .background(Color(ColorScheme.messageTextFieldBackgroundColor).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 20))
//            .glassEffect(.clear.tint(.blue.opacity(0.1)), in: .capsule)
            .glassEffect(.regular.interactive(), in: .capsule)
            
//            .tint(.clear)
    }
}
