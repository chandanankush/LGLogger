//
//  LGOverlayWindow.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import SwiftUI
import UIKit

/// A transparent, always-on-top window added alongside a scene's own window. Only the
/// bubble — or the log viewer, once it's presented — intercepts touches; everywhere else
/// passes straight through to the app underneath, so it never blocks normal use of the app.
final class LGOverlayWindow: UIWindow {
    private let state: LGOverlayState
    private let bubbleTouchRadius: CGFloat = 40

    init(windowScene: UIWindowScene, state: LGOverlayState) {
        self.state = state
        super.init(windowScene: windowScene)

        windowLevel = .alert + 1
        backgroundColor = .clear
        isHidden = false

        let hosting = UIHostingController(rootView: LGBubbleView(state: state))
        hosting.view.backgroundColor = .clear
        rootViewController = hosting
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("LGOverlayWindow does not support NSCoding")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if state.isPresentingLogs {
            return super.hitTest(point, with: event)
        }
        let dx = point.x - state.bubbleCenter.x
        let dy = point.y - state.bubbleCenter.y
        guard (dx * dx + dy * dy) <= bubbleTouchRadius * bubbleTouchRadius else { return nil }
        return super.hitTest(point, with: event)
    }
}
