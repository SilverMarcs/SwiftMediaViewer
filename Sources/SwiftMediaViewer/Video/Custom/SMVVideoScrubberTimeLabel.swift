//
//  SMVVideoScrubberTimeLabel.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The "current / total" time shown above the scrubber while dragging.
struct SMVVideoScrubberTimeLabel: View {
    let current: Double
    let total: Double

    var body: some View {
        HStack {
            Text(SMVVideoTimeFormat.string(for: current))
                .foregroundStyle(.white)
            Text("/")
                .foregroundStyle(.white.opacity(0.6))
            Text(SMVVideoTimeFormat.string(for: total))
                .foregroundStyle(.white.opacity(0.6))
        }
        .font(.headline.monospacedDigit())
        .shadow(color: .black.opacity(0.5), radius: 2)
        .accessibilityHidden(true)
    }
}
#endif
