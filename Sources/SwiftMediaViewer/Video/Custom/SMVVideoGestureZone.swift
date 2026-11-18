//
//  SMVVideoGestureZone.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// One strip of a page that reports taps, double-taps and, on the edges, holds
/// to the page's interaction.
///
/// Tap gestures rather than a Button: the zones need tap counts and holds.
struct SMVVideoGestureZone: View {
    /// How long an edge must be held before playback speeds up.
    static let holdDuration: Double = 0.35

    let zone: SMVVideoTapZone
    let interaction: SMVVideoInteraction
    let playback: SMVVideoPlayback?
    /// Shows or hides the controls after a plain single tap.
    let toggleControls: () -> Void

    var body: some View {
        Color.clear
            .contentShape(.rect)
            // Declared before the single tap so the system waits for it.
            .onTapGesture(count: 2) {
                interaction.handleDoubleTap(in: zone, playback: playback)
            }
            .onTapGesture {
                if interaction.handleTap(in: zone, playback: playback) {
                    toggleControls()
                }
            }
            // Recognised alongside the taps above (see its coordinator).
            .gesture(
                SMVHoldGesture(minimumDuration: Self.holdDuration) {
                    interaction.beginHold(in: zone, playback: playback)
                } onEnded: {
                    interaction.endHold(playback: playback)
                }
            )
    }
}
#endif
