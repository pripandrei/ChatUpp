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

    private(set) var chatsNavigationController: UINavigationController?
    private(set) var settingsNavigationController: UINavigationController?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        tabBar.isHidden = true
    }
    
    func setupTabBarController() {
        chatsVC = ChatsViewController()
        settingsVC = SettingsViewController()
        
        chatsNavigationController = UINavigationController(rootViewController: chatsVC!)
        settingsNavigationController = UINavigationController(rootViewController: settingsVC!)
        
        chatsNavigationController?.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        settingsNavigationController?.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [chatsNavigationController!,settingsNavigationController!]
        
        tabBar.isHidden = false
    }

    deinit {
        print("TABBAR Deninit")
    }
}
