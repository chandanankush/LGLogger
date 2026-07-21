//
//  LGBubbleView.swift
//
//
//  Created by Chandan Singh on 2026/07/20.
//

import SwiftUI

/// The floating, draggable bubble. Tapping it presents `LGLogViewerView`.
struct LGBubbleView: View {
    @ObservedObject var state: LGOverlayState

    private let radius = LGOverlayState.bubbleRadius

    var body: some View {
        // A full-screen, safe-area-ignoring container anchored top-leading, so (0, 0) here
        // is the window's true top-left corner — the same origin `LGOverlayWindow.hitTest`
        // and `state.bubbleCenter` (from `scene.coordinateSpace.bounds`) already use.
        // `.position()` was tried first, but it lays out relative to the safe-area-adjusted
        // canvas, which offset the rendered bubble from where hit-testing expected it.
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(Color.black.opacity(0.75))
                .frame(width: radius * 2, height: radius * 2)
                .overlay {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(.white)
                }
                .offset(x: state.bubbleCenter.x - radius, y: state.bubbleCenter.y - radius)
                .gesture(
                    // .global so `location` lines up with the same raw window coordinates.
                    //
                    // Tap-to-open is handled here too (via onEnded's translation distance)
                    // rather than with a separate `.onTapGesture` — two competing gesture
                    // recognizers on the same view without explicit priority lets SwiftUI's
                    // default exclusivity logic swallow the touch before dragging ever starts.
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            state.bubbleCenter = state.clamp(value.location)
                        }
                        .onEnded { value in
                            let dragDistance = hypot(value.translation.width, value.translation.height)
                            if dragDistance < 10 {
                                state.isPresentingLogs = true
                            }
                        }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .sheet(isPresented: $state.isPresentingLogs) {
            LGLogViewerView()
        }
    }
}
