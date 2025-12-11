//
//  NavigationBarAppearance.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 12/10/25.
//
import UIKit

struct NavigationBarAppearance
{
    static let appearance: UINavigationBarAppearance =
    {
        let appearance = UINavigationBarAppearance()
        
        appearance.backgroundColor = ColorScheme.navigationBarBackgroundColor.withAlphaComponent(0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
//        appearance.shadowColor = .white.withAlphaComponent(0.2)
        appearance.shadowColor = ColorScheme.separatorIndicatorColor.withAlphaComponent(0.4)
        
        appearance.titleTextAttributes = [
            .foregroundColor:  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
            .font: UIFont(name: "HelveticaNeue-bold", size: 17)!
        ]
        
        return appearance
    }()
    
    static func setupNavigationBarGlobalAppearance()
    {
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
    
//    static public func clearNavigationBarAppearance()
//    {
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundColor = .clear
//        appearance.shadowColor = .clear
//
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().compactAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//        UINavigationBar.appearance().isTranslucent = true
//    }

    static func resetScrollEdgeAppearance()
    {
        UINavigationBar.appearance().scrollEdgeAppearance = nil
    }
    
    static func setScrollEdgeAppearance()
    {
        UINavigationBar.appearance().scrollEdgeAppearance = self.appearance
    }
}
