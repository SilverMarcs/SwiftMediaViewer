//
//  SMVVideoPageContext.swift
//  SwiftMediaViewer
//

import Foundation

/// What an app's overlay knows about the video page it sits on.
public struct SMVVideoPageContext {
    /// The page's video.
    public let item: SMVVideoItem
    /// Whether this page is the one on screen.
    public let isCurrent: Bool
    /// Whether the controls are showing. A single tap toggles this; overlays
    /// usually appear only while it's `true`.
    public let isShowingControls: Bool
}
