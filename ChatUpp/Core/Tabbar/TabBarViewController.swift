//
//  TabBarController.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 8/30/23.
//

import UIKit

class TabBarViewController: UITabBarController {
    
//    var customNavigationController: UINavigationController?
//    var secondVC: SettingsViewController? = SettingsViewController()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        setupTabBarController()
    }
    
    private(set) var chatsVC: ChatsViewController?
    private(set) var settingsVC: SettingsViewController?
    
    lazy var customNavigationController = UINavigationController(rootViewController: chatsVC ?? ChatsViewController())
    
    func setupTabBarController() {
        chatsVC = ChatsViewController()
        settingsVC = SettingsViewController()
        
        customNavigationController.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        settingsVC?.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [customNavigationController,settingsVC!]
    }
    
    deinit {
        print("TABBAR Deninit")
    }
}
