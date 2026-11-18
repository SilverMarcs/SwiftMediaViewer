//
//  SMVVideoViewer.swift
//  SwiftMediaViewer
//

import SwiftUI

/// Which fullscreen viewer `SMVVideo` opens.
///
/// The custom viewer is a full-screen cover that zooms out of the inline
/// video, so the system zoom gestures close it and the app's own bars never
/// change. It is available on iOS only; elsewhere `.custom` opens `.native`.
public struct SMVVideoViewer {
    /// Whether a tap opens the custom viewer rather than AVKit's player.
    let isCustom: Bool
    /// The opened video's item ID, as overlays see it in `SMVVideoPageContext`.
    let itemID: String?
    /// Makes a fresh feed for one opening, or `nil` for a single video.
    let makeFeed: (@MainActor () -> any SMVVideoFeed)?
    let scrubber: SMVVideoScrubberMode
    /// The app's content over each page. Erased so `SMVVideoViewer` needs no generic parameter.
    let overlay: @MainActor (SMVVideoPageContext) -> AnyView

    /// AVKit's `VideoPlayer` in a full-screen cover. This is the default.
    public static var native: SMVVideoViewer {
        SMVVideoViewer(isCustom: false, itemID: nil, makeFeed: nil, scrubber: .withControls) { _ in
            AnyView(EmptyView())
        }
    }

    /// The custom viewer, with nothing drawn over the videos.
    ///
    /// - Parameters:
    ///   - itemID: The opened video's `SMVVideoItem` ID. Defaults to its URL.
    ///   - scrubber: Whether pages have a scrubber along the bottom.
    ///   - feed: Supplies the endless vertical feed below the opened video.
    ///     Called once each time the viewer opens, so every opening starts
    ///     fresh. Pass `nil` to show only the opened video.
    public static func custom(
        itemID: String? = nil,
        scrubber: SMVVideoScrubberMode = .withControls,
        feed: (@MainActor () -> any SMVVideoFeed)? = nil
    ) -> SMVVideoViewer {
        custom(itemID: itemID, scrubber: scrubber, feed: feed) { _ in EmptyView() }
    }

    /// The custom viewer, with the app's own content over each page.
    ///
    /// - Parameters:
    ///   - itemID: The opened video's `SMVVideoItem` ID. Defaults to its URL.
    ///   - scrubber: Whether pages have a scrubber along the bottom.
    ///   - feed: Supplies the endless vertical feed below the opened video.
    ///     Pass `nil` to show only the opened video.
    ///   - overlay: Your own content for each page, such as a Save button. It's
    ///     laid out over the video inside the safe area and above the scrubber.
    ///     Empty space passes touches through to the video's gestures.
    public static func custom<Overlay: View>(
        itemID: String? = nil,
        scrubber: SMVVideoScrubberMode = .withControls,
        feed: (@MainActor () -> any SMVVideoFeed)? = nil,
        @ViewBuilder overlay: @escaping @MainActor (SMVVideoPageContext) -> Overlay
    ) -> SMVVideoViewer {
        SMVVideoViewer(isCustom: true, itemID: itemID, makeFeed: feed, scrubber: scrubber) { context in
            AnyView(overlay(context))
        }
    }
}
