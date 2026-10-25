//
//  KeyboardWindowLocator.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 10/25/26.
//

import UIKit
import ObjectiveC

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
    /// process-wide `keyboardWillChangeFrame` observer. The reference
    /// implementation owns this via a long-lived root coordinator; here the
    /// locator does it, because presenters are transient and would otherwise
    /// miss every notification that fired before their creation.
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

    /// "Keyboard on screen" in the same terms as the reference
    /// implementation: a real end frame below the top edge of the screen.
    static func isKeyboardFrameUp(relativeTo window: UIWindow?) -> Bool
    {
        let screenHeight = window?.bounds.height ?? UIScreen.main.bounds.height
        return keyboardFrame.height > 0 && keyboardFrame.minY < screenHeight
    }

    // MARK: - Window lookup

    /// Names of the private accessors tried per object, in order. The
    /// reference implementation (Telegram-style) reads
    /// `windowScene.keyboardSceneDelegate.keyboardWindow`; other revisions
    /// place the accessor differently, so candidates cover both spellings
    /// and the underscore-variant naming UIKit uses for such properties.
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

        print("MENUPIPE[\(pipeTimestamp())]  KWL no route produced a window - keyboardFrame up check pending, running probe")
        /// The delegate route can also fail when the accessor lives at a
        /// different position on this OS revision. Probe the private surface
        /// once per process so the exact names are visible in the console.
        probe(scene: scene)
        return nil
    }

    // MARK: - Debug probe

    private static var didProbe = false

    /// One-shot diagnostic: prints the scene's class, every method of its
    /// class containing "keyboard" / "window", any candidate keyboard scene
    /// delegate objects for the whole scene list and THEIR selector
    /// surface. Output goes through the MENUPIPE channel, and the exact
    /// names found here get wired into the selector lists above.
    private static func probe(scene: UIWindowScene)
    {
        guard !didProbe else { return }
        didProbe = true

        print("MENUPIPE[\(pipeTimestamp())]  KWL probe - scene class \(type(of: scene))")
        dumpKeyboardSelectors(on: scene)

        for connected in UIApplication.shared.connectedScenes
        {
            let isKeyboardScene = NSStringFromClass(type(of: connected)).lowercased().contains("keyboard")
            print("MENUPIPE[\(pipeTimestamp())]  KWL probe - connected scene \(type(of: connected))\(isKeyboardScene ? "  <-- KEYBOARD SCENE" : "")")
            dumpKeyboardSelectors(on: connected)
        }

        for sceneSelectorName in sceneDelegateSelectors
        {
            let sceneSelector = NSSelectorFromString(sceneSelectorName)
            guard scene.responds(to: sceneSelector),
                  let delegate = scene.perform(sceneSelector)?.takeUnretainedValue() as? NSObject
            else
            {
                print("MENUPIPE[\(pipeTimestamp())]  KWL probe - scene responds to \(sceneSelectorName): \(scene.responds(to: sceneSelector))")
                continue
            }
            print("MENUPIPE[\(pipeTimestamp())]  KWL probe - delegate via \(sceneSelectorName): \(type(of: delegate))")
            dumpKeyboardSelectors(on: delegate)
            for windowSelectorName in windowSelectors
            {
                let windowSelector = NSSelectorFromString(windowSelectorName)
                let responds = delegate.responds(to: windowSelector)
                let window = responds
                    ? delegate.perform(windowSelector)?.takeUnretainedValue() as? UIWindow
                    : nil
                print("MENUPIPE[\(pipeTimestamp())]  KWL probe - delegate \(windowSelectorName): responds \(responds), window \(window.map(String.init(describing:)) ?? "nil")")
            }
        }
    }

    private static func dumpKeyboardSelectors(on object: NSObject)
    {
        let klass = type(of: object)
        var count: UInt32 = 0
        guard let methods = class_copyMethodList(klass, &count) else { return }
        var names: [String] = []
        for index in 0..<Int(count)
        {
            let name = NSStringFromSelector(method_getName(methods[index]))
            let lowered = name.lowercased()
            if lowered.contains("keyboard") || lowered.contains("window") || lowered.contains("delegate")
            {
                names.append(name)
            }
        }
        print("MENUPIPE[\(pipeTimestamp())]  KWL probe - \(klass) matching selectors: \(names)")
    }
}
