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
        Group {
            #if os(macOS)
            VideoPlayer(player: player)
            #else
            SMVPlayerLayerView(player: player)
            #endif
        }
        .matchedGeometryEffect(id: videoURL, in: ns)
        .overlay(
            Button(action: {
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

    private func setupPlayer() async {
        guard let url = URL(string: videoURL), player == nil else { return }

        // Perform resource setup off the main actor/thread
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredPeakBitRate = 2_000_000

        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = muteOnPlay

        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        await MainActor.run {
            self.playerLooper = looper
            self.player = queuePlayer

            if autoplay {
                queuePlayer.play()
            }
        }
    }

    private func cleanupPlayer() {
        let oldPlayer = player
        let oldLooper = playerLooper
        
        player = nil
        playerLooper = nil
        
        if let p = oldPlayer {
            p.pause()
            oldLooper?.disableLooping()
            
            // Perform slow player-item replacement off the main thread
            Task.detached(priority: .background) {
                p.replaceCurrentItem(with: nil)
            }
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
