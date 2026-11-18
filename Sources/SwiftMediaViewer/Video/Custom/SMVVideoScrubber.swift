//
//  SMVVideoScrubber.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// A thin progress line with a tall invisible hit area. Dragging or tapping
/// it seeks; while dragging, the line thickens and the times appear.
struct SMVVideoScrubber: View {
    /// The line's thickness at rest.
    static let restingThickness: CGFloat = 2.5
    /// The line's thickness while scrubbing.
    static let scrubbingThickness: CGFloat = 7
    /// The height of the touch target around the line.
    static let hitAreaHeight: CGFloat = 44

    let playback: SMVVideoPlayback
    /// Whether the line is drawn while not scrubbing. Hidden, it can still be
    /// dragged and stays available to VoiceOver.
    let isLineVisible: Bool

    @State private var trackWidth: CGFloat = 0
    @State private var scrubStartCount = 0
    @GestureState private var isDragging = false

    var body: some View {
        VStack {
            if playback.isScrubbing {
                SMVVideoScrubberTimeLabel(current: playback.displayTime, total: playback.duration)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            SMVVideoScrubberTrack(
                progress: playback.progress,
                thickness: playback.isScrubbing ? Self.scrubbingThickness : Self.restingThickness
            )
            .opacity(isLineVisible || playback.isScrubbing ? 1 : 0)
            .frame(maxWidth: .infinity)
            .frame(height: Self.hitAreaHeight)
            .contentShape(.rect)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                trackWidth = width
            }
            // High priority so a drag here scrubs instead of paging.
            .highPriorityGesture(scrubGesture)
        }
        .animation(.snappy(duration: 0.2), value: playback.isScrubbing)
        // Fades in and out the same way however the line was brought up.
        .animation(.snappy(duration: 0.2), value: isLineVisible)
        .sensoryFeedback(.impact(weight: .light), trigger: scrubStartCount)
        .onChange(of: isDragging) { _, dragging in
            // A cancelled drag never reaches `onEnded`, so finish the scrub here.
            if !dragging { playback.endScrubbing() }
        }
        .accessibilityElement()
        .accessibilityLabel("Playback position")
        .accessibilityValue(SMVVideoTimeFormat.accessibilityValue(current: playback.displayTime, total: playback.duration))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                playback.skip(by: SMVVideoPlayback.skipInterval)
            case .decrement:
                playback.skip(by: -SMVVideoPlayback.skipInterval)
            @unknown default:
                break
            }
        }
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                if !playback.isScrubbing {
                    playback.beginScrubbing()
                    scrubStartCount += 1
                }
                playback.scrub(toFraction: fraction(at: value.location.x))
            }
            .onEnded { value in
                playback.scrub(toFraction: fraction(at: value.location.x))
                playback.endScrubbing()
            }
    }

    private func fraction(at x: CGFloat) -> Double {
        guard trackWidth > 0 else { return 0 }
        return Double(min(max(x / trackWidth, 0), 1))
    }
}
#endif
