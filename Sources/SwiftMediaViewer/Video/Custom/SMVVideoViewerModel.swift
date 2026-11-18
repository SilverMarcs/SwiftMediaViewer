//
//  SMVVideoViewerModel.swift
//  SwiftMediaViewer
//

#if os(iOS)
import AVFoundation
import SwiftUI

/// Owns the custom viewer's pages, their players and the feed for one presentation.
///
/// Only the current page holds a player; it loads when the page becomes
/// current and is released when it stops being current. Page 0 borrows the inline `SMVVideo` player, so opening the
/// viewer doesn't reload the video, and `tearDown()` hands it back in its
/// earlier mute and play state.
@MainActor
@Observable
final class SMVVideoViewerModel {
    /// How many pages from the end the next batch is requested.
    static let prefetchDistance = 2
    /// How long the controls stay up without interaction, matching AVKit's player.
    /// They stay up while scrubbing or holding for 2×.
    static let controlsAutoHideDelay: Duration = .seconds(3)

    /// The pages, the opened video first.
    private(set) var items: [SMVVideoItem]
    /// The page the scroll view rests on.
    var currentID: SMVVideoItem.ID?
    /// The current page's player, keyed by item ID.
    private(set) var playbacks: [SMVVideoItem.ID: SMVVideoPlayback] = [:]
    /// Whether a request for the next batch is in flight.
    private(set) var isLoadingMore = false
    /// Whether the controls are showing: the scrubber line (in `.withControls`
    /// mode) and whatever the app overlays. A single tap toggles it; it carries
    /// over from page to page.
    private(set) var isShowingControls = false

    private let feed: (any SMVVideoFeed)?
    private let playbackURL: (SMVVideoItem) -> URL?
    private let onPlayerChange: (SMVVideoItem.ID, AVPlayer?) -> Void
    @ObservationIgnored private var hasReachedEnd: Bool
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var autoHideTask: Task<Void, Never>?
    @ObservationIgnored private var seenIDs: Set<SMVVideoItem.ID>
    @ObservationIgnored private var seenURLs: Set<URL>
    @ObservationIgnored private var playingURL: URL?
    @ObservationIgnored private var resumesWhenActive = false
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var isTornDown = false

    private let initialID: SMVVideoItem.ID
    private let inlinePlayer: AVPlayer?
    private let inlineWasMuted: Bool
    private let inlineWasPlaying: Bool

    /// - Parameters:
    ///   - initialItem: The opened video, shown as page 0.
    ///   - inlinePlayer: The inline view's player for `initialItem`, reused for page 0.
    ///   - feed: Supplies pages below the opened video, or `nil` for a single video.
    init(
        initialItem: SMVVideoItem,
        inlinePlayer: AVPlayer?,
        feed: (any SMVVideoFeed)?,
        playbackURL: @escaping (SMVVideoItem) -> URL? = { $0.url },
        onPlayerChange: @escaping (SMVVideoItem.ID, AVPlayer?) -> Void = { _, _ in }
    ) {
        items = [initialItem]
        currentID = initialItem.id
        initialID = initialItem.id
        seenIDs = [initialItem.id]
        seenURLs = Set([initialItem.url].compactMap { $0 })
        self.feed = feed
        self.playbackURL = playbackURL
        self.onPlayerChange = onPlayerChange
        hasReachedEnd = feed == nil
        self.inlinePlayer = inlinePlayer
        inlineWasMuted = inlinePlayer?.isMuted ?? true
        inlineWasPlaying = inlinePlayer.map { $0.timeControlStatus != .paused } ?? false
    }

    /// The position of the current page in `items`.
    var currentIndex: Int? {
        items.firstIndex { $0.id == currentID }
    }

    var currentPlaybackURL: URL? {
        currentIndex.flatMap { playbackURL(items[$0]) }
    }

    /// The current page's player.
    var currentPlayback: SMVVideoPlayback? {
        currentID.flatMap { playbacks[$0] }
    }

    /// Whether the current page's scrubber is being dragged, which locks paging.
    var isScrubbing: Bool {
        currentPlayback?.isScrubbing ?? false
    }

    /// The page that's pinched in, if any.
    private(set) var zoomedPageID: SMVVideoItem.ID?

    /// Whether the current page is zoomed in, which stops the feed paging.
    var isZoomed: Bool {
        zoomedPageID != nil && zoomedPageID == currentID
    }

    func pageDidChangeZoom(_ id: SMVVideoItem.ID, isZoomed: Bool) {
        if isZoomed {
            zoomedPageID = id
        } else if zoomedPageID == id {
            zoomedPageID = nil
        }
    }

    // MARK: Events

    /// Shows or hides the scrubber and the buttons.
    func toggleControls() {
        isShowingControls.toggle()
        controlsDidInteract()
    }

    /// Restarts the auto-hide countdown after an interaction, such as a skip,
    /// a scrub or play/pause.
    func controlsDidInteract() {
        autoHideTask?.cancel()
        autoHideTask = nil
        guard isShowingControls, !isTornDown else { return }
        autoHideTask = Task { [weak self] in
            try? await Task.sleep(for: Self.controlsAutoHideDelay)
            guard !Task.isCancelled, let self else { return }
            if !isScrubbing, currentPlayback?.isFastForwarding != true {
                isShowingControls = false
                autoHideTask = nil
            } else {
                // Still scrubbing or holding for 2×: keep them up and look again later.
                controlsDidInteract()
            }
        }
    }

    /// Shows the controls after a pause; a resume hides them at once.
    /// Either way, a tap or the auto-hide timer takes them away afterwards.
    func playbackActivityDidChange(_ activity: SMVVideoPlaybackActivity?) {
        guard let activity, !isTornDown else { return }
        switch activity.kind {
        case .adjusted:
            isShowingControls = true
            controlsDidInteract()
        case .resumed:
            isShowingControls = false
            controlsDidInteract()
        }
    }


    /// Prepares the first pages and starts playback. Safe to call more than once.
    func start() {
        guard !hasStarted else { return }
        if isTornDown { playbacks.removeAll() }
        isTornDown = false
        hasStarted = true
        syncPlayers()
        loadMoreIfNeeded()
    }

    /// Moves playback to the new current page and loads more when near the end.
    func currentPageDidChange() {
        guard hasStarted, !isTornDown else { return }
        syncPlayers()
        loadMoreIfNeeded()
    }

    func currentPlaybackURLDidChange() {
        guard hasStarted else { return }
        syncPlayers()
    }

    /// Pauses in the background and resumes when the app becomes active again.
    func scenePhaseDidChange(to phase: ScenePhase) {
        guard !isTornDown else { return }
        switch phase {
        case .background:
            if let playback = currentPlayback, playback.isPlaying {
                playback.pause()
                resumesWhenActive = true
            }
        case .active:
            if resumesWhenActive {
                resumesWhenActive = false
                currentPlayback?.play()
            }
        default:
            break
        }
    }

    /// Releases every owned player, ends the feed and restores the inline
    /// player's mute and play state. Safe to call more than once.
    func tearDown() {
        guard !isTornDown else { return }
        isTornDown = true
        hasStarted = false
        resumesWhenActive = false
        loadTask?.cancel()
        loadTask = nil
        autoHideTask?.cancel()
        autoHideTask = nil
        isLoadingMore = false
        for (id, playback) in playbacks {
            onPlayerChange(id, nil)
            playback.release()
        }
        playingURL = nil
        // Keep the borrowed playback so page 0 keeps rendering the inline
        // player while the dismissal zooms back into the inline view.
        playbacks = playbacks.filter { !$0.value.ownsPlayer }
        if let inlinePlayer {
            inlinePlayer.isMuted = inlineWasMuted
            if inlineWasPlaying {
                inlinePlayer.play()
            } else {
                inlinePlayer.pause()
            }
        }
    }

    // MARK: Players

    /// Loads a player for the current page on demand and releases any other.
    private func syncPlayers() {
        guard let index = currentIndex else { return }
        let current = items[index]
        let url = currentPlaybackURL

        for (id, playback) in playbacks where id != current.id || playingURL != url {
            onPlayerChange(id, nil)
            playback.release()
            playbacks[id] = nil
        }
        guard playbacks[current.id] == nil else { return }

        let playback: SMVVideoPlayback
        if current.id == initialID, let inlinePlayer {
            playback = SMVVideoPlayback(borrowing: inlinePlayer)
        } else if let url {
            playback = SMVVideoPlayback(url: url)
        } else {
            return
        }
        playbacks[current.id] = playback
        playingURL = url
        playback.player.isMuted = false
        onPlayerChange(current.id, playback.player)
        playback.play()
    }

    // MARK: Feed

    /// Requests the next batch when the current page is near the end, unless
    /// a request is running or the feed has ended.
    private func loadMoreIfNeeded() {
        guard feed != nil, !hasReachedEnd, loadTask == nil, !isTornDown,
              let index = currentIndex,
              items.count - 1 - index <= Self.prefetchDistance
        else { return }

        isLoadingMore = true
        loadTask = Task { [weak self] in
            guard let feed = self?.feed else { return }
            let result: Result<[SMVVideoItem], any Error>
            do {
                result = .success(try await feed.nextVideos())
            } catch {
                result = .failure(error)
            }
            guard !Task.isCancelled else { return }
            self?.finishLoading(with: result)
        }
    }

    private func finishLoading(with result: Result<[SMVVideoItem], any Error>) {
        loadTask = nil
        isLoadingMore = false
        guard !isTornDown else { return }

        // A failed request is retried the next time the current page changes.
        guard case .success(let batch) = result else { return }
        guard !batch.isEmpty else {
            hasReachedEnd = true
            return
        }

        var fresh: [SMVVideoItem] = []
        for item in batch where !seenIDs.contains(item.id) {
            if let url = item.url, !seenURLs.insert(url).inserted { continue }
            seenIDs.insert(item.id)
            fresh.append(item)
        }
        // A batch of only duplicates isn't the end; ask again on the next page change.
        guard !fresh.isEmpty else { return }

        items.append(contentsOf: fresh)
        syncPlayers()
        loadMoreIfNeeded()
    }
}
#endif
