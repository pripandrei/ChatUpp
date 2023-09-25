//
//  Utilities.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/25/23.
//

import UIKit

struct Utilities {
    
    static func findLoginViewControllerInHierarchy() -> UIViewController? {
        let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController

        if let tabBarController = rootViewController as? UITabBarController,
           let navController = (tabBarController.children.first) as? UINavigationController,
           let conversationsVC = navController.topViewController as? ConversationsViewController,
           let loginVC = conversationsVC.presentedViewController as? LoginViewController {
            return loginVC
        }
        return nil
    }
}
