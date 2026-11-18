//
//  SMVCustomVideoViewer.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// The custom fullscreen video viewer: a vertical paging feed of videos with
/// gesture controls, an optional scrubber and the app's overlay on each page.
///
/// Page 0 is the opened video. With a feed, swiping up shows the next video
/// and swiping down the previous one. It is a full-screen cover, so the
/// zoom transition's swipe and pinch close it; the hardware buttons set the volume.
struct SMVCustomVideoViewer<Overlay: View>: View {
    @Bindable var model: SMVVideoViewerModel
    let scrubber: SMVVideoScrubberMode
    var isFullScreen = true
    let overlay: (SMVVideoPageContext) -> Overlay

    @Environment(\.scenePhase) private var scenePhase

    @State private var safeArea = EdgeInsets()

    var body: some View {
        // The stack keeps the safe area so its inset can be read; the pages ignore it.
        ZStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(model.items) { item in
                        SMVVideoPage(
                            item: item,
                            playback: model.playbacks[item.id],
                            safeArea: isFullScreen ? safeArea : EdgeInsets(),
                            isShowingControls: model.isShowingControls,
                            scrubber: scrubber,
                            toggleControls: model.toggleControls,
                            onZoomChange: { zoomed in model.pageDidChangeZoom(item.id, isZoomed: zoomed) }
                        ) {
                            overlay(SMVVideoPageContext(
                                item: item,
                                isCurrent: item.id == model.currentID,
                                isShowingControls: model.isShowingControls
                            ))
                        }
                        .containerRelativeFrame([.horizontal, .vertical])
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $model.currentID)
            .scrollIndicators(.hidden)
            // A single video doesn't bounce, leaving vertical swipes to the
            // zoom transition's interactive close.
            .scrollBounceBehavior(.basedOnSize)
            // The scrubber's drag owns the gesture while it's moving.
            // A zoomed page pans instead of paging.
            .scrollDisabled(model.isScrubbing || model.isZoomed)
            // Vertical only: on iPad the sidebar's leading inset keeps videos beside it.
            .ignoresSafeArea(.container, edges: isFullScreen ? .vertical : [])
        }
        .onGeometryChange(for: EdgeInsets.self) { proxy in
            proxy.safeAreaInsets
        } action: { insets in
            safeArea = insets
        }
        .background(.black)
        .statusBarHidden(isFullScreen)
        .onAppear {
            model.start()
        }
        .onDisappear {
            model.tearDown()
        }
        // Play/pause, holds, skips and scrubs all count as activity for auto-hide.
        .onChange(of: model.currentPlayback?.isPlaying) {
            model.controlsDidInteract()
        }
        .onChange(of: model.currentPlayback?.targetTime) {
            model.controlsDidInteract()
        }
        .onChange(of: model.currentPlayback?.lastActivity) { _, activity in
            model.playbackActivityDidChange(activity)
        }
        .onChange(of: model.currentID) {
            model.currentPageDidChange()
        }
        .onChange(of: model.currentPlaybackURL) {
            model.currentPlaybackURLDidChange()
        }
        .onChange(of: scenePhase) { _, phase in
            model.scenePhaseDidChange(to: phase)
        }
    }
}
#endif
