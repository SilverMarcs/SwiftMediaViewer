//
//  SMVVideoInteraction.swift
//  SwiftMediaViewer
//

#if os(iOS)
import Observation

/// Turns a page's taps and holds into playback actions. It draws nothing.
///
/// - A single tap shows or hides the controls (the page decides what that means),
///   except on the play spot in the middle, where it plays or pauses at once.
/// - A double-tap in the center plays or pauses.
/// - A double-tap on an edge skips 5 s and starts a run, during which every
///   further tap on that side adds another 5 s (YouTube-style).
/// - Holding an edge plays at 2× until release, and the tap that ends the
///   hold is ignored.
///
/// The edges recognise double-taps with the system's `TapGesture(count: 2)`;
/// counting taps by hand dropped the second tap of quick double-taps.
@MainActor
@Observable
final class SMVVideoInteraction {
    /// How long a run of skips stays open after the last tap.
    static let skipRunWindow: Duration = .milliseconds(700)

    /// Whether an edge is being held for 2× playback.
    private(set) var isHolding = false

    @ObservationIgnored private var skipRunZone: SMVVideoTapZone?
    @ObservationIgnored private var skipRunTask: Task<Void, Never>?
    @ObservationIgnored private var ignoresTapsUntil: ContinuousClock.Instant?

    // MARK: Taps

    /// Handles a single tap in `zone`. The lift that ends a hold also arrives here.
    ///
    /// - Returns: `true` when the tap should show or hide the controls, `false`
    ///   when it ended a hold or continued a run of skips.
    func handleTap(in zone: SMVVideoTapZone, playback: SMVVideoPlayback?) -> Bool {
        if isHolding {
            endHold(playback: playback)
            return false
        }
        guard acceptsTaps else { return false }
        if zone.isEdge, skipRunZone == zone, let playback {
            // Taps during an open run keep skipping.
            skip(in: zone, playback: playback)
            return false
        }
        endSkipRun()
        return true
    }

    /// Handles a double-tap: skips on an edge (or keeps a run going), plays or pauses in the center.
    func handleDoubleTap(in zone: SMVVideoTapZone, playback: SMVVideoPlayback?) {
        guard let playback, acceptsTaps else { return }
        guard zone.isEdge else {
            endSkipRun()
            playback.togglePlayPause()
            return
        }
        // Within a run both taps count, as they would as separate taps.
        let steps = skipRunZone == zone ? 2 : 1
        for _ in 0..<steps { skip(in: zone, playback: playback) }
    }

    private var acceptsTaps: Bool {
        guard !isHolding else { return false }
        if let ignoresTapsUntil, ContinuousClock.now < ignoresTapsUntil { return false }
        return true
    }

    private func skip(in zone: SMVVideoTapZone, playback: SMVVideoPlayback) {
        playback.skip(by: zone.skipDirection * SMVVideoPlayback.skipInterval)
        skipRunZone = zone
        skipRunTask?.cancel()
        skipRunTask = Task { [weak self] in
            try? await Task.sleep(for: Self.skipRunWindow)
            guard !Task.isCancelled, let self else { return }
            self.skipRunTask = nil
            self.skipRunZone = nil
        }
    }

    /// Plays or pauses straight away from the play spot in the middle of the page.
    func handlePlaySpotTap(playback: SMVVideoPlayback?) {
        guard let playback, acceptsTaps else { return }
        endSkipRun()
        playback.togglePlayPause()
    }

    private func endSkipRun() {
        skipRunTask?.cancel()
        skipRunTask = nil
        skipRunZone = nil
    }

    // MARK: Holds

    /// Starts 2× playback once a hold on an edge is recognised.
    func beginHold(playback: SMVVideoPlayback?) {
        guard let playback, !isHolding else { return }
        endSkipRun()
        isHolding = true
        playback.beginFastForward()
    }

    /// Returns to normal speed when the finger lifts or the hold is cancelled.
    func endHold(playback: SMVVideoPlayback?) {
        guard isHolding else { return }
        isHolding = false
        playback?.endFastForward()
        // The lift that ends a hold can also be reported as a tap.
        ignoresTapsUntil = ContinuousClock.now.advanced(by: .milliseconds(300))
    }

    // MARK: Lifecycle

    /// Cancels pending work and any hold, for when the page leaves the screen.
    func reset(playback: SMVVideoPlayback?) {
        endHold(playback: playback)
        endSkipRun()
    }
}
#endif
