//
//  SMVVideoViewerPage.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The pushed navigation page that hosts the custom viewer.
///
/// It zooms out of its source when it has one, and hides the bars, so the
/// system's back and zoom gestures are the way out.
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
            .toolbar(.hidden, for: .navigationBar, .tabBar)
            .onAppear {
                route.link.isPresented = true
            }
            .onDisappear {
                route.link.isPresented = false
            }
    }
}
#endif
