//
//  SMVVideo.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//

import SwiftUI
import AVKit

public struct SMVVideo: View {
    let videoURL: String
    let thumbnailURL: URL?
    let autoplay: Bool
    let autoplayDelay: Duration
    let muteOnPlay: Bool
    let viewer: SMVVideoViewer

    @Namespace private var ns

    @State private var showModal = false
    @State private var player: AVPlayer?
    /// Rewinds the single item at its end. Cheaper than `AVPlayerLooper`,
    /// which keeps several copies of the item decoding while a list scrolls.
    @State private var looping: Task<Void, Never>?
    /// Ties this video to the custom viewer it opens.
    @State private var viewerLink: SMVVideoViewerLink?
    /// The custom viewer's open presentation, or `nil` while it's closed.
    @State private var viewerRoute: SMVVideoViewerRoute?
    /// Set once the video has really played, after which the poster is removed.
    @State private var hasStartedPlaying = false
    /// Whether most of the video is on screen, as its scroll view reports it.
    /// `nil` until a scroll view reports, or always outside one.
    @State private var isMostlyVisible: Bool?

    /// How much of the video must be on screen for it to autoplay. Below this it pauses.
    static let autoplayVisibleFraction = 0.6

    /// - Parameters:
    ///   - videoURL: The video to play inline and fullscreen.
    ///   - thumbnailURL: A poster kept behind the video, so it starts on the
    ///     poster instead of a blank box, and any moment the player draws nothing
    ///     (before its first frame, or briefly as playback starts) shows the
    ///     poster rather than the background. Use a frame of the video itself.
    ///   - autoplay: Whether the inline video plays on its own while at least 60%
    ///     of it is on screen in its scroll view. It pauses below that and resumes
    ///     when scrolled back. Outside a scroll view it plays once it appears.
    ///   - autoplayDelay: How long a mostly visible video waits before autoplaying. The
    ///     player loads at once; the wait only skips videos scrolled straight past.
    ///   - muteOnPlay: Whether the inline video starts muted.
    ///   - viewer: The fullscreen viewer a tap opens. Defaults to `.native`.
    ///     The custom viewer is iOS-only; elsewhere it falls back to `.native`.
    public init(videoURL: String, thumbnailURL: URL? = nil, autoplay: Bool = true,
                autoplayDelay: Duration = .zero, muteOnPlay: Bool = true, viewer: SMVVideoViewer = .native) {
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.autoplay = autoplay
        self.autoplayDelay = autoplayDelay
        self.muteOnPlay = muteOnPlay
        self.viewer = viewer
    }

    public var body: some View {
        Group {
            #if os(macOS)
            VideoPlayer(player: player)
            #else
            SMVPlayerLayerView(player: player)
            #endif
        }
        // The player layer is clear wherever it has no frame, so the poster
        // behind it shows through until the video covers it.
        .background {
            if let thumbnailURL, !hasStartedPlaying {
                CachedAsyncImage(url: thumbnailURL, targetSize: 600) {
                    Color.clear
                }
                .scaledToFit()
            }
        }
        .matchedGeometryEffect(id: videoURL, in: ns)
        #if os(iOS)
        .matchedTransitionSource(id: videoURL, in: ns)
        #endif
        .overlay(
            Button(action: {
                #if os(iOS)
                if openCustomViewer() { return }
                #endif
                showModal = true
            }) {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        )
        .onScrollVisibilityChange(threshold: Self.autoplayVisibleFraction) { visible in
            isMostlyVisible = visible
        }
        // Restarts whenever visibility changes, so it plays or pauses to match.
        .task(id: isMostlyVisible) {
            await updateAutoplay()
        }
        .onDisappear {
            // Behind an open viewer, the viewer is still playing this player.
            guard viewerLink?.isPresented != true else { return }
            cleanupPlayer()
        }
        .smvVideoViewer(item: $viewerRoute, scrubber: viewer.scrubber) { viewer.overlay($0) }
        .conditionalFullScreen(isPresented: $showModal) {
            VideoPlayer(player: player)
                #if !os(macOS)
                .navigationTransition(.zoom(sourceID: videoURL, in: ns))
                #endif
                .ignoresSafeArea()
        }
    }

    /// Presents the custom viewer. Returns `false` when this video uses the
    /// native viewer, or on platforms without the custom one.
    private func openCustomViewer() -> Bool {
        #if os(iOS)
        guard viewer.isCustom, let url = URL(string: videoURL) else { return false }
        let item = SMVVideoItem(id: viewer.itemID ?? videoURL, url: url)
        let link = viewerLink ?? SMVVideoViewerLink(initialItem: item)
        link.initialItem = item
        link.player = player
        link.makeFeed = viewer.makeFeed
        link.sourceID = videoURL
        // Set before presenting, so autoplay leaves the player to the viewer.
        link.isPresented = true
        viewerLink = link
        viewerRoute = SMVVideoViewerRoute(link: link, namespace: ns)
        return true
        #else
        return false
        #endif
    }

    /// Loads the player once, then plays it while mostly visible and pauses it otherwise.
    private func updateAutoplay() async {
        setupPlayer()
        // Behind an open viewer page, the page is driving this player.
        guard autoplay, let current = player, viewerLink?.isPresented != true else { return }
        if isMostlyVisible == false {
            current.pause()
            return
        }
        // Cancelled when visibility changes or the view leaves the screen.
        do {
            try await Task.sleep(for: autoplayDelay)
        } catch {
            return
        }
        guard player === current, isMostlyVisible != false else { return }
        current.play()
        // Drop the poster only once playback has visibly moved on.
        while !Task.isCancelled, !hasStartedPlaying, player === current {
            if current.timeControlStatus == .playing,
               current.currentTime().seconds > SMVPlayerLoop.posterHideTime {
                hasStartedPlaying = true
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func setupPlayer() {
        guard let url = URL(string: videoURL), player == nil else { return }
        let (newPlayer, item) = SMVPlayerLoop.makePlayer(url: url)
        newPlayer.isMuted = muteOnPlay
        player = newPlayer
        looping = SMVPlayerLoop.loop(item, on: newPlayer)
    }

    private func cleanupPlayer() {
        hasStartedPlaying = false
        looping?.cancel()
        looping = nil
        guard let oldPlayer = player else { return }
        player = nil
        oldPlayer.pause()
        // Emptying a player can be slow, so keep it off the main thread.
        Task.detached(priority: .background) {
            oldPlayer.replaceCurrentItem(with: nil)
        }
    }
}

#if !os(macOS)
class SMVVideoPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

struct SMVPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?
    
    func makeUIView(context: Context) -> SMVVideoPlayerUIView {
        let view = SMVVideoPlayerUIView()
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: SMVVideoPlayerUIView, context: Context) {
        uiView.player = player
    }
}
#endif
