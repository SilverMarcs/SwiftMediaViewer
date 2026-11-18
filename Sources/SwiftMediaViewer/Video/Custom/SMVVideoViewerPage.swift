//
//  SMVVideoViewerPage.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The full-screen cover that hosts the custom viewer.
///
/// It zooms out of its source when it has one, so the zoom transition's swipe
/// and pinch are the way out. Being a cover, it leaves the app's navigation
/// and tab bars untouched underneath.
struct SMVVideoViewerPage<Overlay: View>: View {
    let route: SMVVideoViewerRoute
    let scrubber: SMVVideoScrubberMode
    let overlay: (SMVVideoPageContext) -> Overlay

    @State private var model: SMVVideoViewerModel

    init(route: SMVVideoViewerRoute, scrubber: SMVVideoScrubberMode,
         overlay: @escaping (SMVVideoPageContext) -> Overlay) {
        self.route = route
        self.scrubber = scrubber
        self.overlay = overlay
        let link = route.link
        // Creating a model is cheap: players and the feed start only in `start()`.
        _model = State(initialValue: SMVVideoViewerModel(
            initialItem: link.initialItem,
            inlinePlayer: link.player,
            feed: link.makeFeed?()
        ))
    }

    var body: some View {
        SMVCustomVideoViewer(model: model, scrubber: scrubber, overlay: overlay)
            .modifier(SMVZoomTransition(sourceID: route.link.sourceID, namespace: route.namespace))
            .onAppear {
                route.link.isPresented = true
            }
            .onDisappear {
                route.link.isPresented = false
            }
    }
}
#endif
