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
    
//    lazy var customNavigationController: UINavigationController = UINavigationController(rootViewController: chatsVC ?? ChatsViewController())
    var customNavigationController: UINavigationController?
    
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
