//
//  SMVVideoPage.swift
//  SwiftMediaViewer
//

#if os(iOS)
import SwiftUI

/// One full-screen page of the custom viewer: the video over black, its
/// gesture zones, the app's overlay and the scrubber fixed along the bottom.
///
/// A single tap toggles the controls. With `.withControls` the scrubber line
/// shows only then, but is always there to drag.
struct SMVVideoPage<Overlay: View>: View {
    let item: SMVVideoItem
    /// The page's player, or `nil` while the page is outside the player window.
    let playback: SMVVideoPlayback?
    /// The viewer's safe area, which the page itself ignores.
    let safeArea: EdgeInsets
    let isShowingControls: Bool
    let scrubber: SMVVideoScrubberMode
    let toggleControls: () -> Void
    /// Reports whether this page is zoomed in, which stops the feed paging.
    let onZoomChange: (Bool) -> Void
    @ViewBuilder let overlay: () -> Overlay

    @State private var interaction = SMVVideoInteraction()
    /// Set once this page's video has really played, after which the thumbnail goes.
    @State private var hasStartedPlaying = false
    @State private var zoom = SMVVideoZoom()
    @State private var pageSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black

            // Behind the video until it has really played, as in the timeline: the
            // player layer is clear wherever it has no frame, so loading shows this.
            // Only the picture zooms; the gestures, overlay and scrubber stay put.
            ZStack {
                if !hasStartedPlaying {
                    SMVVideoThumbnail(item: item)
                }

                SMVPlayerSurfaceView(player: playback?.player) { _ in }
                    .accessibilityHidden(true)
            }
            .scaleEffect(zoom.scale)
            .offset(zoom.offset)

            SMVVideoGestureLayer(item: item, interaction: interaction, playback: playback,
                                 toggleControls: toggleControls)

            VStack(spacing: 0) {
                // The app's content: inside the safe area, above the scrubber.
                overlay()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if scrubber != .none {
                    if let playback {
                        SMVVideoScrubber(playback: playback,
                                         isLineVisible: scrubber == .always || isShowingControls
                                            // Briefly for skips, and only while a 2× hold lasts.
                                            || playback.isFlashingProgress || playback.isFastForwarding)
                    } else {
                        Color.clear
                            .frame(height: SMVVideoScrubber.hitAreaHeight)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, safeArea.top)
            .padding(.bottom, safeArea.bottom)
            .animation(.easeOut(duration: 0.25), value: isShowingControls)
        }
        .clipped()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            pageSize = size
        }
        // Pinch out to zoom, pinch in to zoom back out; at 1× an inward pinch
        // is left to the zoom transition, which closes the viewer.
        .gesture(
            SMVPinchGesture { [zoom] in
                zoom.isZoomed
            } onBegan: { focus in
                zoom.beginPinch(at: centered(focus))
            } onChanged: { scale, focus in
                zoom.updatePinch(scale: scale, focus: centered(focus))
            } onEnded: {
                zoom.endPinch(pageSize: pageSize)
            }
        )
        .gesture(
            SMVZoomPanGesture { [zoom] in
                zoom.isZoomed
            } onBegan: {
                zoom.beginPan()
            } onChanged: { translation in
                zoom.updatePan(translation: translation)
            } onEnded: {
                zoom.endPan(pageSize: pageSize)
            }
        )
        .onChange(of: zoom.isZoomed) { _, zoomed in
            onZoomChange(zoomed)
        }
        .onChange(of: playback?.currentTime ?? 0) { _, time in
            if !hasStartedPlaying, playback?.isPlaying == true, time > SMVPlayerLoop.posterHideTime {
                hasStartedPlaying = true
            }
        }
        .onChange(of: playback == nil) {
            // A released page loses its player mid-hold or mid-tap; drop that state.
            if playback == nil {
                interaction.reset(playback: nil)
                hasStartedPlaying = false
            }
        }
        .onDisappear {
            interaction.reset(playback: playback)
            zoom.reset()
        }
    }

    /// A point in the page's own space, measured from its center instead.
    private func centered(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - pageSize.width / 2, y: point.y - pageSize.height / 2)
    }
}
#endif
