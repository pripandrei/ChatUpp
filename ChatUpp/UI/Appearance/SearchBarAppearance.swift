//
//  SearchBarAppearance.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 1/26/26.
//

import UIKit
struct SearchBarAppearance
{
    static func setUISearchBarAppearance()
    {
        let appearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        appearance.attributedPlaceholder = NSAttributedString(string: "Search users",
                                                              attributes: [.foregroundColor: UIColor.systemGray])
        UISearchBar.appearance().setImage(
            UIImage(systemName: "magnifyingglass")?
                .withTintColor(UIColor.systemGray,
                               renderingMode: .alwaysOriginal),
            for: .search,
            state: .normal
        )
    }
}
