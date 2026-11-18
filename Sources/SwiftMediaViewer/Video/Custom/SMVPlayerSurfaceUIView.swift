//
//  SMVPlayerSurfaceUIView.swift
//  SwiftMediaViewer
//

#if os(iOS)
import AVFoundation
import UIKit

/// Hosts an `AVPlayerLayer` with aspect-fit video and reports when its first
/// frame is ready, so the page can show a thumbnail until then.
final class SMVPlayerSurfaceUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var readyObservation: NSKeyValueObservation?

    /// Called on the main actor whenever the layer's readiness changes.
    var onReadyForDisplayChange: ((Bool) -> Void)?

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
        readyObservation = Self.observeReadiness(of: playerLayer) { [weak self] isReady in
            guard let self else { return }
            Task { @MainActor in
                self.onReadyForDisplayChange?(isReady)
            }
        }
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

    /// Observes readiness from a nonisolated context, because KVO may call
    /// back on any thread.
    private nonisolated static func observeReadiness(
        of layer: AVPlayerLayer,
        handler: @escaping @Sendable (Bool) -> Void
    ) -> NSKeyValueObservation {
        layer.observe(\.isReadyForDisplay, options: [.initial, .new]) { layer, _ in
            handler(layer.isReadyForDisplay)
        }
    }
}
#endif
