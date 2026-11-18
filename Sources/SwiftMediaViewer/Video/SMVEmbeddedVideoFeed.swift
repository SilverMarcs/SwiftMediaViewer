#if os(iOS)
import AVFoundation
import SwiftUI

/// The custom paged viewer embedded in an app's own screen, inside its safe area.
public struct SMVEmbeddedVideoFeed<Overlay: View>: View {
    @State private var model: SMVVideoViewerModel

    private let scrubber: SMVVideoScrubberMode
    private let overlay: (SMVVideoPageContext) -> Overlay

    /// `playbackURL` reads the current item's resolved stream URL. It may return
    /// nil while the host loads that URL. `onPlayerChange` receives nil immediately
    /// before a player is released.
    public init(
        firstItem: SMVVideoItem,
        feed: any SMVVideoFeed,
        scrubber: SMVVideoScrubberMode = .withControls,
        playbackURL: @escaping (SMVVideoItem) -> URL? = { $0.url },
        onPlayerChange: @escaping (SMVVideoItem.ID, AVPlayer?) -> Void = { _, _ in },
        @ViewBuilder overlay: @escaping (SMVVideoPageContext) -> Overlay
    ) {
        _model = State(initialValue: SMVVideoViewerModel(
            initialItem: firstItem,
            inlinePlayer: nil,
            feed: feed,
            playbackURL: playbackURL,
            onPlayerChange: onPlayerChange
        ))
        self.scrubber = scrubber
        self.overlay = overlay
    }

    public var body: some View {
        SMVCustomVideoViewer(model: model, scrubber: scrubber, isFullScreen: false, overlay: overlay)
            // The scroll view can draw into the surrounding bars' safe areas.
            .clipped()
    }
}
#endif
