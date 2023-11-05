//
//  Utilities.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/25/23.
//

import UIKit

struct Utilities {
    
//    static func findLoginViewControllerInHierarchy() -> UIViewController? {
//        let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
//
//        if let tabBarController = rootViewController as? TabBarViewController,
//           let navController = (tabBarController.children.first) as? UINavigationController,
//           let conversationsVC = navController.topViewController as? ChatsViewController,
//           let loginNavController = conversationsVC.presentedViewController as? UINavigationController,
//           let loginVC = loginNavController.topViewController as? LoginViewController
//        {
//            return loginVC
//        }
//        return nil
//    }
    
    static func findLoginViewControllerInHierarchy() -> UIViewController? {
        let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController

        if let tabBarController = rootViewController as? TabBarViewController,
           let loginNavController = tabBarController.presentedViewController as? UINavigationController,
           let loginVC = loginNavController.topViewController as? LoginViewController
        {
            return loginVC
        }
        return nil
    }
    
    static func findChatsViewControllerInHierarchy() -> UIViewController? {
        let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
        
        if let tabBarController = rootViewController as? UITabBarController,
           let navController = (tabBarController.children.first) as? UINavigationController,
           let chatsVC = navController.topViewController as? ChatsViewController {
            return chatsVC
        }
        return nil
    }
    
    static func findNavVCInHierarchy() -> UINavigationController? {
        let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
        
        if let tabBarController = rootViewController as? UITabBarController,
           let navController = (tabBarController.children.first) as? UINavigationController {
            return navController
        }
        return nil
    }
    
    static public func setupNavigationBarAppearance() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            
            appearance.backgroundColor = #colorLiteral(red: 0.1057919934, green: 0.2902272344, blue: 0.4154375792, alpha: 1).withAlphaComponent(0.8)
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.shadowColor = .white.withAlphaComponent(0.5)
            
            appearance.titleTextAttributes = [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), .font: UIFont(name: "HelveticaNeue-bold", size: 17)!]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().barTintColor = #colorLiteral(red: 0.1057919934, green: 0.2902272344, blue: 0.4154375792, alpha: 1).withAlphaComponent(0.8)
        }
    }

    static var windowRoot: TabBarViewController? {
        get {
            return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController as? TabBarViewController
        }
        set {
            guard let newValue = newValue else {return}
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController = newValue
        }
    }
}

