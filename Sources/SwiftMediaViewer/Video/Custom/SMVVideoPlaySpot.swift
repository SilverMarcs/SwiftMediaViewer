//
//  SMVVideoPlaySpot.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// A spot in the middle of the page where a single tap plays or pauses at
/// once, instead of showing the controls. It has no double-tap, so it never waits.
///
/// It covers the middle 40% of the width and 30% of the height.
struct SMVVideoPlaySpot: View {
    let interaction: SMVVideoInteraction
    let playback: SMVVideoPlayback?

    var body: some View {
        Color.clear
            .contentShape(.rect)
            .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: 0)
            .containerRelativeFrame(.vertical, count: 10, span: 3, spacing: 0)
            .onTapGesture {
                interaction.handlePlaySpotTap(playback: playback)
            }
    }
}
#endif
