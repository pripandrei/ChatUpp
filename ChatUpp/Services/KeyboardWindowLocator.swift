//
//  KeyboardWindowLocator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/25/26.
//

import UIKit

// MARK: - Keyboard window lookup  ⚠️ PRIVATE API
//
// The keyboard lives in its own window (UIRemoteKeyboardWindow, level 1e7+1).
// An app window can never be placed above it (UIKit clamps app windows to
// 1e7), and the window is hidden from UIApplication.windows /
// UIWindowScene.windows. The only way to show something over the keyboard is
// to add a view INTO that window.
//
// Risks: undocumented API (App Review may object, iOS updates may break it).
// It can return nil before the keyboard was first shown or if the keyboard
// UI is hosted out of process, so callers must always have a fallback.
// Do NOT use +[UIRemoteKeyboardWindow remoteKeyboardWindowForScreen:create:],
// it traps when linked against newer SDKs.
enum KeyboardWindowLocator
{
    // MARK: - Keyboard presence tracking

    /// The frame the keyboard will occupy for its current state, kept by a
    /// process-wide `keyboardWillChangeFrame` observer. Presenters are
    /// transient, so they would otherwise miss every notification that fired
    /// before their creation; the tracker is therefore installed once in
    /// `AppDelegate.application(_:didFinishLaunchingWithOptions:)`.
    private static var keyboardFrame: CGRect = .zero
    private static var frameTrackingObserver: NSObjectProtocol?

    /// Installs the frame tracker at most once; safe to call repeatedly.
    static func installFrameTracking()
    {
        if frameTrackingObserver != nil { return }
        frameTrackingObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main) { note in
                keyboardFrame =
                    (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        }
    }

    /// "Keyboard on screen" in the usual terms: a real end frame below the
    /// top edge of the screen (guards against hardware-keyboard edge cases
    /// where an empty keyboard window exists without a visible keyboard).
    static func isKeyboardFrameUp(relativeTo window: UIWindow?) -> Bool
    {
        let screenHeight = window?.bounds.height ?? UIScreen.main.bounds.height
        return keyboardFrame.height > 0 && keyboardFrame.minY < screenHeight
    }

    // MARK: - Window lookup

    /// Private accessor spellings tried in order. The known route is
    /// `windowScene.keyboardSceneDelegate.keyboardWindow`; the underscore
    /// variants cover OS revisions that use UIKit's other property naming.
    private static let sceneDelegateSelectors = ["keyboardSceneDelegate",
                                                 "_keyboardSceneDelegate"]
    private static let windowSelectors = ["keyboardWindow", "_keyboardWindow"]

    static func window(in scene: UIWindowScene) -> UIWindow?
    {
        for sceneSelectorName in sceneDelegateSelectors
        {
            let sceneSelector = NSSelectorFromString(sceneSelectorName)
            guard scene.responds(to: sceneSelector),
                  let delegate = scene.perform(sceneSelector)?.takeUnretainedValue() as? NSObject
            else { continue }

            for windowSelectorName in windowSelectors
            {
                let windowSelector = NSSelectorFromString(windowSelectorName)
                guard delegate.responds(to: windowSelector),
                      let window = delegate.perform(windowSelector)?.takeUnretainedValue() as? UIWindow
                else { continue }
                return window
            }
        }
        return nil
    }
}
