//
//  SMVVideoFeed.swift
//  SwiftMediaViewer
//

import Foundation

/// Supplies the custom viewer's videos below the opened one.
///
/// The custom viewer asks for the next batch when the person is a couple of
/// pages from the end, never runs two requests at once, and drops items whose
/// `id` or `url` it already shows.
@MainActor
public protocol SMVVideoFeed: AnyObject {
    /// Next batch to append. Return `[]` when the feed has ended.
    ///
    /// Throwing doesn't tear the viewer down: the viewer asks again the next
    /// time the person approaches the end.
    func nextVideos() async throws -> [SMVVideoItem]
}
