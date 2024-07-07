//
//  AppDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import Firebase
import Network
//import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
//    var monitor: NWPathMonitor?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        IQKeyboardManager.shared.enable = true
        FirebaseApp.configure()
        Utilities.setupNavigationBarAppearance()
//        checkNetworkConnection()
        return true
    }
    
//    private func checkNetworkConnection() {
//        monitor = NWPathMonitor()
//        monitor?.start(queue: DispatchQueue(label: "NetworkMonitor"))
//        monitor?.pathUpdateHandler = { (path) in
//            if path.status == .satisfied {
//                print("Connected")
//            } else {
//                print("Not Connected")
//            }
//        }
//    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
         Task {
             try await UserManager.shared.updateUser(with: authUser.uid, usingName: nil, onlineStatus: false)
         }
    }


    func applicationWillTerminate(_ application: UIApplication) {
        print("App Terminated")
       let authUser = try! AuthenticationManager.shared.getAuthenticatedUser()
        Task {
            try await UserManager.shared.updateUser(with: authUser.uid, usingName: nil, onlineStatus: false)
        }
    }
}



