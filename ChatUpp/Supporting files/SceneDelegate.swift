//
//  SceneDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import SwiftUI

//import FirebaseDatabase
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: MainCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let tabBarController = TabBarViewController()
        coordinator = MainCoordinator(tabBar: tabBarController)
        
        window?.overrideUserInterfaceStyle = .dark
        
        /// The tab bar controller is wrapped in an outer navigation controller
        /// (mirroring NavigationStack { TabView { ... } }): screens pushed on
        /// the outer stack slide over the full window while the tab bar stays
        /// alive underneath, simply covered by the pushed view controller.
        let outerNavController = UINavigationController(rootViewController: tabBarController)
        outerNavController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = outerNavController
        window?.makeKeyAndVisible()
        
        #if DEV
        installDevEnvironmentBadge()
        #endif
        
        coordinator?.start()
        
        _ = KeyboardService.shared
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

//MARK: - Dev environment badge

#if DEV
extension SceneDelegate
{
    /// pinned to the window itself, so it shows on every screen (login
    /// included) without being wired into each view controller - keeps
    /// "which firebase project am I looking at" answerable at a glance
    private func installDevEnvironmentBadge()
    {
        let badge = UILabel()
        badge.text = "DEV"
        badge.font = .systemFont(ofSize: 11, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.85)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 5
        badge.clipsToBounds = true
        badge.isUserInteractionEnabled = false
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.layer.zPosition = .greatestFiniteMagnitude

        guard let window else { return }
        window.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 40),
            badge.heightAnchor.constraint(equalToConstant: 20),
            badge.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            badge.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 8 - 20)
        ])
    }
}
#endif

