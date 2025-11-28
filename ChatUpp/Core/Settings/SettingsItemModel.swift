//
//  SettingsItemModel.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/28/23.
//

import Foundation

//MARK: - SETTINGS LIST ITEM MODEL
struct SettingsItem: Hashable {
    let name: String
    let iconName: String
    
    static var itemsData = [
        SettingsItem(name: "Edit profile", iconName: "edit_profile_icon"),
        SettingsItem(name: "Switch theme", iconName: "appearance_icon"),
        SettingsItem(name: "Delete profile", iconName: "delete_profile_icon"),
        SettingsItem(name: "Log out", iconName: "log_out_icon")
    ]
}
