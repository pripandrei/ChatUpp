//
//  View+Extensions.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/12/25.
//

import SwiftUI

extension View
{
    func errorAlert(title: String,
                    message: String,
                    isPresented: Binding<Bool>) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button("Ok", role: .cancel) {
                isPresented.wrappedValue = false
            }
        } message: {
            Text(message)
        }
    }
}

struct AlertModifier: ViewModifier
{
    @Binding var isPresented: Bool
    var message: String
    
    func body(content: Content) -> some View {
        content.alert("Network Error", isPresented: $isPresented) {
            Button("Ok", role: .none) {
                isPresented = false
            }
        } message: {
            Text(message)
        }
    }
}
