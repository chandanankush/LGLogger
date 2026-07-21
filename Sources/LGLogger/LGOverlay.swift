//
//  LGOverlay.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import UIKit

/// Installs a floating, draggable bubble that stays on top of every screen in the app —
/// including every window of a multi-window / document-based app — and shows the saved log
/// files on tap.
///
/// Call `LGOverlay.install()` once, e.g. from your `App`'s `init()`. It attaches lazily to
/// every scene as it becomes key, so it works whether scenes already exist or connect later,
/// and it cleans itself up when a scene disconnects.
@MainActor
public enum LGOverlay {
    private static var overlaysByScene: [ObjectIdentifier: LGOverlayWindow] = [:]
    private static var isInstalled = false

    public static func install() {
        guard !isInstalled else { return }
        isInstalled = true

        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            MainActor.assumeIsolated {
                guard let window = notification.object as? UIWindow,
                      !(window is LGOverlayWindow),
                      let scene = window.windowScene
                else { return }
                attach(to: scene)
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { notification in
            MainActor.assumeIsolated {
                guard let scene = notification.object as? UIWindowScene else { return }
                overlaysByScene.removeValue(forKey: ObjectIdentifier(scene))
            }
        }

        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                attach(to: windowScene)
            }
        }
    }

    private static func attach(to scene: UIWindowScene) {
        let key = ObjectIdentifier(scene)
        guard overlaysByScene[key] == nil else { return }

        let bounds = scene.coordinateSpace.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let safeAreaInsets = scene.windows.first(where: { !($0 is LGOverlayWindow) })?.safeAreaInsets ?? .zero

        let defaultCenter = CGPoint(x: bounds.width - 40, y: bounds.height - 120)
        let state = LGOverlayState(bubbleCenter: defaultCenter, bounds: bounds, safeAreaInsets: safeAreaInsets)
        overlaysByScene[key] = LGOverlayWindow(windowScene: scene, state: state)
    }
}
