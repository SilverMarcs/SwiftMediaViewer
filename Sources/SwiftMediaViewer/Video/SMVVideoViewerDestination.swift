//
//  SMVVideoViewerDestination.swift
//  SwiftMediaViewer
//

import SwiftUI

public extension View {
    /// Registers the custom video viewer as a destination of the enclosing
    /// `NavigationStack`. Add it once to each stack that pushes `SMVVideoViewerRoute`s.
    ///
    /// - Parameters:
    ///   - scrubber: Whether pages have a scrubber along the bottom.
    ///   - overlay: Your own content for each page, such as a Save button. It's
    ///     laid out over the video inside the safe area and above the scrubber,
    ///     so `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)`
    ///     puts it just above the progress line. Empty space passes touches through
    ///     to the video's gestures.
    func smvVideoViewerDestination<Overlay: View>(
        scrubber: SMVVideoScrubberMode = .withControls,
        @ViewBuilder overlay: @escaping (SMVVideoPageContext) -> Overlay
    ) -> some View {
        navigationDestination(for: SMVVideoViewerRoute.self) { route in
            #if os(iOS)
            SMVVideoViewerPage(route: route, scrubber: scrubber, overlay: overlay)
            #else
            EmptyView()
            #endif
        }
    }

    /// Registers the custom video viewer, with nothing drawn over the videos.
    func smvVideoViewerDestination(scrubber: SMVVideoScrubberMode = .withControls) -> some View {
        smvVideoViewerDestination(scrubber: scrubber) { _ in EmptyView() }
    }
}
