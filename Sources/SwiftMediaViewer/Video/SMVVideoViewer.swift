//
//  SMVVideoViewer.swift
//  SwiftMediaViewer
//

import Foundation

/// Which fullscreen viewer `SMVVideo` opens.
///
/// The custom viewer is a navigation page, pushed with a zoom transition onto
/// the app's own `NavigationStack`, so the system zoom gestures close it. It
/// is available on iOS only; elsewhere `.custom` opens `.native`.
public struct SMVVideoViewer {
    /// The opened video's item ID, as overlays see it in `SMVVideoPageContext`.
    let itemID: String?
    /// Makes a fresh feed for one opening, or `nil` for a single video.
    let makeFeed: (@MainActor () -> any SMVVideoFeed)?
    /// Pushes the viewer's route, or `nil` for AVKit's player.
    let open: (@MainActor (SMVVideoViewerRoute) -> Void)?

    /// AVKit's `VideoPlayer` in a full-screen cover. This is the default.
    public static var native: SMVVideoViewer {
        SMVVideoViewer(itemID: nil, makeFeed: nil, open: nil)
    }

    /// The custom viewer, pushed as a navigation page.
    ///
    /// - Parameters:
    ///   - itemID: The opened video's `SMVVideoItem` ID. Defaults to its URL.
    ///   - feed: Supplies the endless vertical feed below the opened video.
    ///     Called once each time the viewer opens, so every opening starts
    ///     fresh. Pass `nil` to show only the opened video.
    ///   - open: Appends the route to the enclosing stack's path, for example
    ///     `{ path.append($0) }`. That stack needs `.smvVideoViewerDestination()`.
    public static func custom(
        itemID: String? = nil,
        feed: (@MainActor () -> any SMVVideoFeed)? = nil,
        open: @escaping @MainActor (SMVVideoViewerRoute) -> Void
    ) -> SMVVideoViewer {
        SMVVideoViewer(itemID: itemID, makeFeed: feed, open: open)
    }
}
