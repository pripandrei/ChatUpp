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
        view.backgroundColor = .white
    }
    
    func setupTabBarController() {
        chatsVC = ChatsViewController()
        settingsVC = SettingsViewController()
        
        chatsNavigationController = UINavigationController(rootViewController: chatsVC!)
        settingsNavigationController = UINavigationController(rootViewController: settingsVC!)
        
        chatsNavigationController?.tabBarItem = UITabBarItem(title: "Chats", image: nil, tag: 1)
        settingsNavigationController?.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 2)
        
        viewControllers = [chatsNavigationController!,settingsNavigationController!]
    }
    
    func cleanupTabBarItems() {
//        selectedIndex = 0
        //        settingsVC?.coordinatorDelegate = nil
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.selectedIndex = 1
//        }
//        self.selectedIndex = 0
        self.chatsVC = nil
        self.chatsNavigationController = nil
        self.settingsVC = nil
        self.settingsNavigationController = nil
        self.viewControllers = []
        
//        Timer.scheduledTimer(withTimeInterval: 2.1, repeats: false) { [weak self] _ in
//            
//        }
    }
    
    deinit {
        print("TABBAR Deninit")
    }
}
