//
//  AppDelegate.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 6/26/23.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        _ = NetworkMonitor.shared
        FirebaseApp.configure()
        verifyBundledResourcesOnLaunch()
        // Keyboard frame tracking must start before any keyboard activity,
        // otherwise the message menu presenter cannot tell whether the
        // keyboard is up at long-press time (every show notification fired
        // before its creation would be missed).
        KeyboardWindowLocator.installFrameTracking()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application is not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    /// Fail-fast tripwire for package resources that only break at runtime
    /// (e.g. FlagPhoneNumber's country list silently missing from the bundle).
    private func verifyBundledResourcesOnLaunch()
    {
        #if DEBUG
        let countryList = Bundle.FlagPhoneNumber().path(forResource: "countryCodes", ofType: "json")
        assert(countryList != nil, "FlagPhoneNumber resources are missing from the bundle — the local package's resources are not being copied. Check Packages/FlagPhoneNumber/Package.swift.")
        print("✅ Bundled resources verified: FlagPhoneNumber country list present")
        #endif
    }



    func applicationWillTerminate(_ application: UIApplication) {
    }
}

