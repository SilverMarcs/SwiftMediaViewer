//
//  SMVVideoViewerPresentation.swift
//  SwiftMediaViewer
//

import SwiftUI

public extension View {
    /// Presents the custom video viewer as a full-screen cover while `item` is set.
    ///
    /// The cover zooms out of the route's source when it has one. Closing it,
    /// by the zoom transition's swipe or pinch, sets `item` back to `nil`. On
    /// platforms without the custom viewer this does nothing.
    ///
    /// - Parameters:
    ///   - item: The opening to show, or `nil` when the viewer is closed.
    ///   - scrubber: Whether pages have a scrubber along the bottom.
    ///   - overlay: Your own content for each page, such as a Save button. It's
    ///     laid out over the video inside the safe area and above the scrubber,
    ///     so `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)`
    ///     puts it just above the progress line. Empty space passes touches through
    ///     to the video's gestures.
    @ViewBuilder
    func smvVideoViewer<Overlay: View>(
        item: Binding<SMVVideoViewerRoute?>,
        scrubber: SMVVideoScrubberMode = .withControls,
        @ViewBuilder overlay: @escaping (SMVVideoPageContext) -> Overlay
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item) { route in
            SMVVideoViewerPage(route: route, scrubber: scrubber, overlay: overlay)
        }
        #else
        self
        #endif
    }

    /// Presents the custom video viewer, with nothing drawn over the videos.
    func smvVideoViewer(
        item: Binding<SMVVideoViewerRoute?>,
        scrubber: SMVVideoScrubberMode = .withControls
    ) -> some View {
        smvVideoViewer(item: item, scrubber: scrubber) { _ in EmptyView() }
    }
}
