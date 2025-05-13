//
//  Utilities.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/25/23.
//

import UIKit


enum UnwrappingError: Error {
    case nilValueFound(String)
}

struct Utilities {
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
    
    // Set color to Navigation Bar
    static public func setupNavigationBarAppearance()
    {
        let appearance = UINavigationBarAppearance()
        
        appearance.backgroundColor = ColorManager.navigationBarColor.withAlphaComponent(0.9)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.shadowColor = .white.withAlphaComponent(0.5)
        
        appearance.titleTextAttributes = [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), .font: UIFont(name: "HelveticaNeue-bold", size: 17)!]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // Adjust Navigation Bar color to be clear
    static public func clearNavigationBarAppearance() {
//        let appearance = UINavigationBarAppearance()
////        appearance.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
////        appearance.backgroundColor = .clear
////        appearance.shadowColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
////        appearance.shadowColor = .clear
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        UINavigationBar.appearance().standardAppearance.backgroundColor = .clear
        UINavigationBar.appearance().compactAppearance = nil
        UINavigationBar.appearance().scrollEdgeAppearance = nil
        UINavigationBar.appearance().backgroundColor = .clear
    }
    
    static public func configureTransparentNavigationBarAppearance(for controller: UIViewController)
    {
        let transparentAppearance = UINavigationBarAppearance()
        transparentAppearance.configureWithTransparentBackground()
        
        // Set this appearance specifically for this view controller
        controller.navigationItem.standardAppearance = transparentAppearance
        controller.navigationItem.scrollEdgeAppearance = transparentAppearance
        controller.navigationItem.compactAppearance = transparentAppearance
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
    
    static var defaultProfileImage: UIImage {
        return UIImage(named: "default_profile_photo") ?? UIImage()
    }
    
    static func setGradientBackground(forView view: UIView) {
        let colorTop = #colorLiteral(red: 0.6000000238, green: 0.5585549503, blue: 0.5448982104, alpha: 1).cgColor
        let colorBottom = #colorLiteral(red: 0.5186259388, green: 0.4503372039, blue: 0.5165727111, alpha: 1).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}

//MARK: - Test functions
extension Utilities
{
    static func saveImageToDocumentDirectory(_ image: UIImage, to fileName: String)
    {
        let compressedData = image.jpegData(compressionQuality: 1.0)
        let fileName = getDocumentsDirectory().appending(path: fileName)
        print("Saved file path: ", fileName)
        do {
            try compressedData?.write(to: fileName)
            print("success saving image")
        } catch {
            print(error.localizedDescription)
        }
    }
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
