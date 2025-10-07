//
//  FirestoreCollectionName.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/18/23.
//

import Foundation

enum FirestoreCollection: String {
    case chats
    case messages
    case users
    case participantsUserIDs = "participants_user_ids"
}

enum FirestoreField: String {
    case id
    case participants
    case name
}
