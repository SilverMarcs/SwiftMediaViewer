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
            .matchedGeometryEffect(id: videoURL, in: ns)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showModal = true
                        configureAudioSession(active: true)
                    }
            )
            .task {
                await setupPlayer()
            }
            .onDisappear {
                cleanupPlayer()
                configureAudioSession(active: false)
            }
            .conditionalFullScreen(isPresented: $showModal) {
                VideoPlayer(player: player)
                    #if !os(macOS)
                    .navigationTransition(.zoom(sourceID: videoURL, in: ns))
                    #endif
                    .ignoresSafeArea()
                    .onDisappear {
                        configureAudioSession(active: false)
                    }
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
            configureAudioSession(active: true)
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

    private func configureAudioSession(active: Bool) {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            if active {
                // Duck other audio (lowers volume of other apps)
                try audioSession.setCategory(.playback, options: [.duckOthers, .mixWithOthers])
                try audioSession.setActive(true)
            } else {
                // Restore other audio
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            }
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
    }
}
