//
//  LGOverlayState.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import Combine
import SwiftUI
import UIKit

/// Shared, per-scene state for the floating log bubble: its current position (so it can be
/// dragged around), and whether the log viewer is currently presented — `LGOverlayWindow`
/// uses the latter to decide whether to intercept the whole screen or just the bubble.
@MainActor
final class LGOverlayState: ObservableObject {
    static let bubbleRadius: CGFloat = 28

    @Published var bubbleCenter: CGPoint
    @Published var isPresentingLogs = false

    /// The scene's bounds, used to keep the bubble draggable but never off-screen.
    let bounds: CGRect

    /// Keeps the bubble out of the status bar / Dynamic Island / home-indicator margins —
    /// touches there can be reserved by the system regardless of our window's level, so a
    /// bubble dragged into one of those strips could become ungrabbable.
    let safeAreaInsets: UIEdgeInsets

    init(bubbleCenter: CGPoint, bounds: CGRect, safeAreaInsets: UIEdgeInsets) {
        self.bounds = bounds
        self.safeAreaInsets = safeAreaInsets
        self.bubbleCenter = Self.clamp(bubbleCenter, bounds: bounds, safeAreaInsets: safeAreaInsets)
    }

    /// Keeps a candidate center within `bounds` and clear of `safeAreaInsets` on every edge.
    func clamp(_ point: CGPoint) -> CGPoint {
        Self.clamp(point, bounds: bounds, safeAreaInsets: safeAreaInsets)
    }

    private static func clamp(_ point: CGPoint, bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGPoint {
        CGPoint(
            x: min(
                max(point.x, bubbleRadius + safeAreaInsets.left),
                bounds.width - bubbleRadius - safeAreaInsets.right
            ),
            y: min(
                max(point.y, bubbleRadius + safeAreaInsets.top),
                bounds.height - bubbleRadius - safeAreaInsets.bottom
            )
        )
    }
}
