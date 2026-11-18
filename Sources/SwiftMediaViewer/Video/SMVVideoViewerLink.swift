//
//  SMVVideoViewerLink.swift
//  SwiftMediaViewer
//

import AVFoundation

/// What one opening of the custom viewer starts from.
///
/// An inline `SMVVideo` keeps one link for its lifetime and refreshes it on
/// each tap. While its page is open the inline view doesn't release its
/// player when it disappears behind the page, because the page is playing it.
@MainActor
final class SMVVideoViewerLink {
    /// The first page.
    var initialItem: SMVVideoItem
    /// A player already showing `initialItem`, reused so page 0 doesn't reload.
    var player: AVPlayer?
    var makeFeed: (@MainActor () -> any SMVVideoFeed)?
    /// The zoom transition's source ID, or `nil` for a plain cover.
    var sourceID: String?
    /// Whether a viewer from this link is on screen or being presented.
    var isPresented = false

    init(initialItem: SMVVideoItem, player: AVPlayer? = nil,
         makeFeed: (@MainActor () -> any SMVVideoFeed)? = nil, sourceID: String? = nil) {
        self.initialItem = initialItem
        self.player = player
        self.makeFeed = makeFeed
        self.sourceID = sourceID
    }
}
