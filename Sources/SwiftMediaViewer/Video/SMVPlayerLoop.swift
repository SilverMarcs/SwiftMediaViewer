//
//  SMVPlayerLoop.swift
//  SwiftMediaViewer
//

import AVFoundation

/// Loops one player item by rewinding it at its end.
///
/// Cheaper than `AVPlayerLooper`, which keeps several copies of the item decoding.
enum SMVPlayerLoop {
    /// Seconds of actual playback after which a poster behind the video is removed.
    static let posterHideTime: Double = 0.25

    /// A player for `url` that stays on its item at the end, ready to rewind.
    @MainActor
    static func makePlayer(url: URL, preferredPeakBitRate: Double = 0) -> (AVPlayer, AVPlayerItem) {
        let item = AVPlayerItem(url: url)
        item.preferredPeakBitRate = preferredPeakBitRate
        let player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .none
        return (player, item)
    }

    /// Rewinds and replays `item` each time it finishes. Cancel to stop looping.
    @MainActor
    static func loop(_ item: AVPlayerItem, on player: AVPlayer) -> Task<Void, Never> {
        Task { [weak player] in
            let ends = NotificationCenter.default.notifications(
                named: AVPlayerItem.didPlayToEndTimeNotification,
                object: item
            )
            for await _ in ends {
                guard let player else { return }
                await player.seek(to: .zero)
                player.play()
            }
        }
    }
}
