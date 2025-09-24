//
//  SMVVideo.swift
//  SwiftMediaViewer
//
//  Created by Zabir Raihan on 25/09/2025.
//


//
//  SMVVideo.swift
//  SwiftMediaView (standalone folder to be turned into a Swift Package)
//

import SwiftUI
import AVKit

public struct SMVVideo: View {
    let videoURL: String
    let autoplay: Bool
    let muteOnPlay: Bool

    @Namespace private var ns

    @State private var showModal = false
    @State private var player: AVPlayer?
    @State private var playerLooper: AVPlayerLooper?

    public init(videoURL: String, autoplay: Bool = true, muteOnPlay: Bool = true) {
        self.videoURL = videoURL
        self.autoplay = autoplay
        self.muteOnPlay = muteOnPlay
    }

    public var body: some View {
        VideoPlayer(player: player)
            // No aspectRatio or cornerRadius here; caller applies
            .matchedGeometryEffect(id: videoURL, in: ns)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showModal = true
                    }
            )
            .task {
                await setupPlayer()
            }
            .onDisappear {
                cleanupPlayer()
            }
            .fullScreenCover(isPresented: $showModal) {
                VideoPlayer(player: player)
                    .navigationTransition(.zoom(sourceID: videoURL, in: ns))
                    .ignoresSafeArea()
                    .zoomable()
            }
    }

    private func setupPlayer() async {
        guard let url = URL(string: videoURL), player == nil else { return }

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredPeakBitRate = 2_000_000

        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = muteOnPlay

        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        player = queuePlayer

        if autoplay {
            queuePlayer.play()
        }
    }

    private func cleanupPlayer() {
        player?.pause()
        playerLooper?.disableLooping()
        playerLooper = nil
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
}
