//
//  SMVVideoItem.swift
//  SwiftMediaViewer
//

import Foundation

/// One video page in the custom viewer's feed.
public struct SMVVideoItem: Identifiable, Hashable, Sendable {
    /// A stable identifier, used to deduplicate items the feed returns more than once.
    public let id: String
    /// The video to play, if its URL is known before the page becomes current.
    public let url: URL?
    /// An image shown while the video loads.
    public let thumbnailURL: URL?
    /// A short description for VoiceOver, such as the author's name. Not drawn on screen.
    public let title: String?

    public init(id: String, url: URL? = nil, thumbnailURL: URL? = nil, title: String? = nil) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.title = title
    }
}
