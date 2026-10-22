//
//  MessageMenuOption.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/22/26.
//

import UIKit

/// A single action row of the custom message menu. The custom menu replaces
/// the old `UIMenu`/`UIAction` based system context menu, so the options are
/// plain descriptors that a UIKit row can render (title + symbol + color)
/// and run (closure).
struct MessageMenuOption
{
    let title: String
    let image: UIImage?
    let isDestructive: Bool
    /// Runs the option's side effect; overlay dismissal is handled by the menu card,
    /// not by the action itself.
    let action: () -> Void
}
