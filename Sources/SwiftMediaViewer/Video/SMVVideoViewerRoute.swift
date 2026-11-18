//
//  SMVVideoViewerRoute.swift
//  SwiftMediaViewer
//

import SwiftUI

/// One opening of the custom video viewer.
///
/// Present it with `.smvVideoViewer(item:)`. `SMVVideo` with `viewer: .custom(...)`
/// makes and presents these for you; build one directly to open the viewer
/// from your own thumbnail or button.
public struct SMVVideoViewerRoute: Identifiable, Hashable {
    let link: SMVVideoViewerLink
    let namespace: Namespace.ID?

    public var id: ObjectIdentifier { ObjectIdentifier(link) }

    /// Opens the viewer at `item`, with `feed`'s videos below it.
    ///
    /// - Parameters:
    ///   - item: The first video.
    ///   - feed: Called once when the viewer opens. Pass `nil` for a single video.
    ///   - sourceID: Zooms out of the view marked with
    ///     `.matchedTransitionSource(id: sourceID, in: namespace)`. Without it the
    ///     viewer slides up as a plain full-screen cover.
    ///   - namespace: The namespace for `sourceID`.
    @MainActor
    public init(
        item: SMVVideoItem,
        feed: (@MainActor () -> any SMVVideoFeed)? = nil,
        sourceID: String? = nil,
        namespace: Namespace.ID? = nil
    ) {
        link = SMVVideoViewerLink(initialItem: item, makeFeed: feed, sourceID: sourceID)
        self.namespace = namespace
    }

    init(link: SMVVideoViewerLink, namespace: Namespace.ID?) {
        self.link = link
        self.namespace = namespace
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.link === rhs.link && lhs.namespace == rhs.namespace
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(link))
        hasher.combine(namespace)
    }
}
