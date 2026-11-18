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
    /// Ties this video to the custom viewer page it opens.
    @State private var viewerLink: SMVVideoViewerLink?
    /// Set once the video has really played, after which the poster is removed.
    @State private var hasStartedPlaying = false

    /// - Parameters:
    ///   - videoURL: The video to play inline and fullscreen.
    ///   - thumbnailURL: A poster kept behind the video, so it starts on the
    ///     poster instead of a blank box, and any moment the player draws nothing
    ///     (before its first frame, or briefly as playback starts) shows the
    ///     poster rather than the background. Use a frame of the video itself.
    ///   - autoplay: Whether the inline video starts playing on its own.
    ///   - autoplayDelay: How long a visible video waits before autoplaying. The
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
        .task {
            await setupPlayer()
        }
        .onDisappear {
            // Behind an open viewer page, the page is still playing this player.
            guard viewerLink?.isPresented != true else { return }
            cleanupPlayer()
        }
        .conditionalFullScreen(isPresented: $showModal) {
            VideoPlayer(player: player)
                #if !os(macOS)
                .navigationTransition(.zoom(sourceID: videoURL, in: ns))
                #endif
                .ignoresSafeArea()
        }
    }

    /// Pushes the custom viewer page. Returns `false` when this video uses the
    /// native viewer, or on platforms without the custom one.
    private func openCustomViewer() -> Bool {
        #if os(iOS)
        guard let open = viewer.open, let url = URL(string: videoURL) else { return false }
        let item = SMVVideoItem(id: viewer.itemID ?? videoURL, url: url)
        let link = viewerLink ?? SMVVideoViewerLink(initialItem: item)
        link.initialItem = item
        link.player = player
        link.makeFeed = viewer.makeFeed
        link.sourceID = videoURL
        // Set before pushing, so this view's disappearance keeps the player.
        link.isPresented = true
        viewerLink = link
        open(SMVVideoViewerRoute(link: link, namespace: ns))
        return true
        #else
        return false
        #endif
    }

    private func setupPlayer() async {
        guard let url = URL(string: videoURL), player == nil else { return }

        let (newPlayer, item) = SMVPlayerLoop.makePlayer(url: url, preferredPeakBitRate: 2_000_000)
        newPlayer.isMuted = muteOnPlay
        player = newPlayer
        looping = SMVPlayerLoop.loop(item, on: newPlayer)

        guard autoplay else { return }
        // Cancelled with this task when the view leaves the screen.
        do {
            try await Task.sleep(for: autoplayDelay)
        } catch {
            return
        }
        guard player === newPlayer else { return }
        newPlayer.play()
        // Drop the poster only once playback has visibly moved on.
        while !Task.isCancelled, player === newPlayer {
            if newPlayer.timeControlStatus == .playing,
               newPlayer.currentTime().seconds > SMVPlayerLoop.posterHideTime {
                hasStartedPlaying = true
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
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
