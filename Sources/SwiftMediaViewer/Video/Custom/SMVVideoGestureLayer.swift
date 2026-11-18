//
//  SMVVideoGestureLayer.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The page's touch surface: leading and trailing quarters around a center half.
///
/// For VoiceOver it's a single element: activating it plays or pauses, and
/// named actions skip back and forward.
struct SMVVideoGestureLayer: View {
    let item: SMVVideoItem
    let interaction: SMVVideoInteraction
    let playback: SMVVideoPlayback?
    let toggleControls: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(SMVVideoTapZone.allCases, id: \.self) { zone in
                    SMVVideoGestureZone(zone: zone, interaction: interaction, playback: playback,
                                        toggleControls: toggleControls)
                        .containerRelativeFrame(.horizontal, count: 4, span: zone.widthInQuarters, spacing: 0)
                }
            }

            // On top of the center strip: a single tap here plays or pauses.
            SMVVideoPlaySpot(interaction: interaction, playback: playback)
        }
        .accessibilityElement()
        .accessibilityLabel(item.title ?? "Video")
        .accessibilityValue(playback?.isPlaying == true ? "Playing" : "Paused")
        .accessibilityAddTraits(.startsMediaSession)
        .accessibilityAction {
            playback?.togglePlayPause()
        }
        .accessibilityAction(.magicTap) {
            playback?.togglePlayPause()
        }
        .accessibilityAction(named: "Show or hide controls", toggleControls)
        .accessibilityAction(named: "Skip back 5 seconds") {
            playback?.skip(by: -SMVVideoPlayback.skipInterval)
        }
        .accessibilityAction(named: "Skip forward 5 seconds") {
            playback?.skip(by: SMVVideoPlayback.skipInterval)
        }
    }
}
#endif
