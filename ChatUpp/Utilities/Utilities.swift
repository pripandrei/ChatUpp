//
//  Utilities.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 9/25/23.
//

import UIKit
import SkeletonView

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
        
//        appearance.backgroundColor = ColorManager.navigationBarBackgroundColor.withAlphaComponent(0.85)
//        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        appearance.backgroundColor = ColorManager.tabBarBackgroundColor.withAlphaComponent(0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .light)
        
        appearance.shadowColor = .white.withAlphaComponent(0.5)
        
        appearance.titleTextAttributes = [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), .font: UIFont(name: "HelveticaNeue-bold", size: 17)!]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // Adjust Navigation Bar color to be clear
    static public func clearNavigationBarAppearance() {
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
        let colorTop = #colorLiteral(red: 0.7123333812, green: 0.5818203092, blue: 0.5612760186, alpha: 1).cgColor
        let colorBottom = #colorLiteral(red: 0.1738350689, green: 0.125146687, blue: 0.1836120486, alpha: 1).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    ///
    /// Skeleton animation
    static func initiateSkeletonAnimation(for view: UIView)
    {
        let skeletonAnimationColor = ColorManager.skeletonAnimationColor
        let skeletonItemColor = ColorManager.skeletonItemColor
        view.showGradientSkeleton(usingGradient: .init(baseColor: skeletonItemColor, secondaryColor: skeletonAnimationColor), delay: TimeInterval(0), transition: SkeletonTransitionStyle.crossDissolve(0.3))
    }

    static func terminateSkeletonAnimation(for view: UIView) {
        view.stopSkeletonAnimation()
        view.hideSkeleton(transition: .crossDissolve(0.25))
    }
    
    static func stopSkeletonAnimation(for views: UIView...)
    {
        for view in views {
            view.stopSkeletonAnimation()
            view.hideSkeleton(transition: .none)
        }
    }
}


//let colorTop = #colorLiteral(red: 0.6000000238, green: 0.5585549503, blue: 0.5448982104, alpha: 1).cgColor
//let colorBottom = #colorLiteral(red: 0.5186259388, green: 0.4503372039, blue: 0.5165727111, alpha: 1).cgColor


//let colorTop = #colorLiteral(red: 0.6636233926, green: 0.6031231284, blue: 0.6042643189, alpha: 1).cgColor
//let colorBottom = #colorLiteral(red: 0.3588703871, green: 0.2444120347, blue: 0.230712533, alpha: 1).cgColor
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
    
    static func snapshotView(for view: UIView) -> UIView?
    {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        let imageView = UIImageView(image: image)
        imageView.frame = view.bounds
        return imageView
    }

    
}

// Async
func executeAfter(seconds: Double, block: @escaping () -> Void)
{
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: block)
}

func mainQueue(block: @escaping () -> Void)
{
    DispatchQueue.main.async {
        block()
    }
}
