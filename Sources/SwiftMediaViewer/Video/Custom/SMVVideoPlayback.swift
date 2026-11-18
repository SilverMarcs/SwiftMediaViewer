//
//  SMVVideoPlayback.swift
//  SwiftMediaViewer
//

#if os(iOS)
import AVFoundation
import Observation

/// Drives one page's player in the custom viewer and publishes its state.
///
/// A playback either owns its player, which it empties on `release()`, or
/// borrows the inline `SMVVideo` player, which it only pauses and stops
/// observing so the inline view can keep using it.
@MainActor
@Observable
final class SMVVideoPlayback {
    /// The step for skip actions and accessibility adjustments, in seconds.
    static let skipInterval: Double = 5

    /// The player the page renders.
    let player: AVPlayer
    /// Whether `release()` empties the player. `false` for the borrowed inline player.
    let ownsPlayer: Bool

    /// The playhead, in seconds, as last reported by the player.
    private(set) var currentTime: Double = 0
    /// The item's length in seconds, or `0` while it's unknown.
    private(set) var duration: Double = 0
    /// Whether the player is playing or waiting to play.
    private(set) var isPlaying = false
    /// Whether a press-and-hold is playing the video at 2×.
    private(set) var isFastForwarding = false
    /// Whether the scrubber is being dragged.
    private(set) var isScrubbing = false
    /// Where a scrub or seek is heading. Shown instead of `currentTime` so
    /// periodic time updates don't fight the scrubber.
    private(set) var targetTime: Double?
    /// The person's latest skip, pause, resume or hold, for showing and hiding the controls.
    private(set) var lastActivity: SMVVideoPlaybackActivity?

    @ObservationIgnored private var looping: Task<Void, Never>?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var resumesAfterScrub = false
    @ObservationIgnored private var resumesAfterFastForward = false
    @ObservationIgnored private var seekGeneration = 0
    @ObservationIgnored private var isReleased = false

    /// Creates a playback that owns a new looping player for `url`.
    init(url: URL) {
        let (newPlayer, item) = SMVPlayerLoop.makePlayer(url: url)
        player = newPlayer
        ownsPlayer = true
        looping = SMVPlayerLoop.loop(item, on: newPlayer)
        startObserving()
    }

    /// Creates a playback that drives an existing player without owning it.
    init(borrowing player: AVPlayer) {
        self.player = player
        ownsPlayer = false
        let time = player.currentTime()
        if time.isNumeric { currentTime = max(time.seconds, 0) }
        startObserving()
    }

    /// The time the scrubber shows.
    var displayTime: Double { targetTime ?? currentTime }

    /// How far through the video `displayTime` is, from 0 to 1.
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(displayTime / duration, 0), 1)
    }

    // MARK: Playback

    /// Starts or resumes playback, at 2× while fast-forwarding.
    func play() {
        guard !isReleased else { return }
        if isFastForwarding {
            player.rate = 2
        } else {
            player.play()
        }
        isPlaying = true
    }

    /// Pauses playback.
    func pause() {
        player.pause()
        isPlaying = false
    }

    /// Plays when paused and pauses when playing.
    func togglePlayPause() {
        if isPlaying {
            pause()
            recordActivity(.adjusted)
        } else {
            play()
            recordActivity(.resumed)
        }
    }

    private func recordActivity(_ kind: SMVVideoPlaybackActivity.Kind) {
        lastActivity = SMVVideoPlaybackActivity(kind: kind, count: (lastActivity?.count ?? 0) + 1)
    }

    /// Plays at 2× until `endFastForward()`, starting playback if it was paused.
    func beginFastForward() {
        guard !isReleased, !isFastForwarding else { return }
        recordActivity(.adjusted)
        resumesAfterFastForward = isPlaying
        isFastForwarding = true
        player.rate = 2
        isPlaying = true
    }

    /// Returns to 1×, or pauses again if playback was paused before the hold.
    func endFastForward() {
        guard isFastForwarding else { return }
        isFastForwarding = false
        recordActivity(.adjusted)
        guard !isReleased else { return }
        if resumesAfterFastForward {
            player.rate = 1
        } else {
            pause()
        }
    }

    // MARK: Seeking

    /// Seeks precisely by `delta` seconds from the current target, so quick
    /// repeated skips add up rather than restarting from a stale playhead.
    func skip(by delta: Double) {
        seek(to: displayTime + delta, precise: true)
        recordActivity(.adjusted)
    }

    /// Pauses playback for a scrub, remembering whether to resume afterwards.
    func beginScrubbing() {
        guard !isReleased, !isScrubbing else { return }
        resumesAfterScrub = isPlaying
        isScrubbing = true
        targetTime = currentTime
        pause()
    }

    /// Seeks quickly, with tolerance, to `fraction` of the video while scrubbing.
    func scrub(toFraction fraction: Double) {
        guard isScrubbing, duration > 0 else { return }
        seek(to: min(max(fraction, 0), 1) * duration, precise: false)
    }

    /// Seeks precisely to where the scrub ended and resumes the earlier play state.
    func endScrubbing() {
        guard isScrubbing else { return }
        isScrubbing = false
        seek(to: displayTime, precise: true)
        if resumesAfterScrub { play() }
    }

    private func seek(to seconds: Double, precise: Bool) {
        guard !isReleased else { return }
        // Stop short of the end, where the loop would jump back to the start.
        let upper = duration > 0 ? max(duration - 0.1, 0) : Double.greatestFiniteMagnitude
        let target = min(max(seconds, 0), upper)
        targetTime = target
        seekGeneration += 1
        let generation = seekGeneration
        let tolerance = precise ? CMTime.zero : CMTime(seconds: 0.25, preferredTimescale: 600)
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: tolerance,
            toleranceAfter: tolerance
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.seekDidFinish(generation: generation, target: target)
            }
        }
    }

    private func seekDidFinish(generation: Int, target: Double) {
        // A newer seek, or a scrub still in progress, owns `targetTime`.
        guard generation == seekGeneration, !isScrubbing else { return }
        currentTime = target
        targetTime = nil
    }

    // MARK: Lifecycle

    /// Stops observing and pauses. An owned player is also emptied, so it
    /// releases its buffers; a borrowed one is left ready for the inline view.
    func release() {
        guard !isReleased else { return }
        if isFastForwarding {
            isFastForwarding = false
            player.rate = 1
        }
        pause()
        isReleased = true
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        guard ownsPlayer else { return }
        looping?.cancel()
        looping = nil
        let player = self.player
        // Emptying a player can be slow, so keep it off the main thread.
        Task.detached(priority: .background) {
            player.replaceCurrentItem(with: nil)
        }
    }

    private func startObserving() {
        refreshStatus()
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                self?.handleTick(time)
            }
        }
    }

    private func handleTick(_ time: CMTime) {
        refreshStatus()
        guard !isScrubbing, targetTime == nil, time.isNumeric else { return }
        let seconds = max(time.seconds, 0)
        if seconds != currentTime { currentTime = seconds }
    }

    /// Reads play state and duration, assigning only on change to avoid needless redraws.
    private func refreshStatus() {
        let playing = player.timeControlStatus != .paused
        if playing != isPlaying { isPlaying = playing }
        if let itemDuration = player.currentItem?.duration, itemDuration.isNumeric {
            let seconds = itemDuration.seconds
            if seconds > 0, seconds != duration { duration = seconds }
        }
    }
}
#endif
