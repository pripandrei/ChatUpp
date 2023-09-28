//
//  ConversationsViewModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/26/23.
//

import Foundation

final class ChatsViewModel {
    
    //    var userProfile: authDataResultModel?
    
    var isUserSignedOut: ObservableObject<Bool> = ObservableObject(false)
    
    func validateUserAuthentication() {
        let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
        isUserSignedOut.value = authUser == nil
    }
}
