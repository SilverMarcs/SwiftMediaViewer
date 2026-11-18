//
//  SMVVideoScrubberTrack.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The scrubber's visible line: a faint track with the played part filled.
struct SMVVideoScrubberTrack: View {
    /// How much of the track is filled, from 0 to 1.
    let progress: Double
    let thickness: CGFloat

    var body: some View {
        Capsule()
            .fill(.white.opacity(0.2))
            .overlay {
                // Clip a full-width fill so its leading end stays rounded.
                Capsule()
                    .fill(.white.opacity(0.75))
                    .mask {
                        Rectangle()
                            .scaleEffect(x: progress, anchor: .leading)
                    }
            }
            .frame(height: thickness)
            .shadow(color: .black.opacity(0.3), radius: 1)
    }
}
#endif
