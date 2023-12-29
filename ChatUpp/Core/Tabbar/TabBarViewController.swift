//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    private(set) var chatsVC: ChatsViewController?
    private(set) var settingsVC: SettingsViewController?

    private(set) var customNavigationController: UINavigationController?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    func setupTabBarController() {
        chatsVC = ChatsViewController()
        settingsVC = SettingsViewController()
        customNavigationController = UINavigationController(rootViewController: chatsVC!)
        
        customNavigationController?.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        settingsVC?.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [customNavigationController!,settingsVC!]
    }
    
    func cleanupTabBarItems() {
        chatsVC = nil
        settingsVC = nil
        customNavigationController = nil
        viewControllers = []
    }
    
    deinit {
        print("TABBAR Deninit")
    }
}
