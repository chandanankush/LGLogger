//
//  LGOverlayStateTests.swift
//
//  Covers the bubble-clamping geometry that keeps the floating overlay on-screen and clear
//  of the safe-area margins.
//

import XCTest
import UIKit
@testable import LGLogger

@MainActor
final class LGOverlayStateTests: XCTestCase {

    private let bounds = CGRect(x: 0, y: 0, width: 400, height: 800)
    private var radius: CGFloat { LGOverlayState.bubbleRadius }

    private func makeState(insets: UIEdgeInsets = .zero, center: CGPoint = .zero) -> LGOverlayState {
        LGOverlayState(bubbleCenter: center, bounds: bounds, safeAreaInsets: insets)
    }

    func testClampLeavesInteriorPointUnchanged() {
        let state = makeState()
        let inside = CGPoint(x: 200, y: 400)
        XCTAssertEqual(state.clamp(inside), inside)
    }

    func testClampPullsPointInsideTopLeft() {
        let state = makeState()
        XCTAssertEqual(state.clamp(CGPoint(x: -50, y: -50)), CGPoint(x: radius, y: radius))
    }

    func testClampPullsPointInsideBottomRight() {
        let state = makeState()
        let clamped = state.clamp(CGPoint(x: 10_000, y: 10_000))
        XCTAssertEqual(clamped, CGPoint(x: bounds.width - radius, y: bounds.height - radius))
    }

    func testClampRespectsSafeAreaInsets() {
        let insets = UIEdgeInsets(top: 50, left: 10, bottom: 34, right: 20)
        let state = makeState(insets: insets)

        XCTAssertEqual(
            state.clamp(CGPoint(x: -1, y: -1)),
            CGPoint(x: radius + insets.left, y: radius + insets.top)
        )
        XCTAssertEqual(
            state.clamp(CGPoint(x: 10_000, y: 10_000)),
            CGPoint(x: bounds.width - radius - insets.right, y: bounds.height - radius - insets.bottom)
        )
    }

    func testInitialCenterIsClamped() {
        let state = makeState(center: CGPoint(x: -100, y: -100))
        XCTAssertEqual(state.bubbleCenter, CGPoint(x: radius, y: radius))
    }
}
