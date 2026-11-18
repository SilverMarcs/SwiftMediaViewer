//
//  SMVVideoPlaybackActivity.swift
//  SwiftMediaViewer
//

#if os(iOS)
/// The latest thing the person did to a page's playback, which decides
/// whether the controls appear or go away.
struct SMVVideoPlaybackActivity: Equatable {
    enum Kind: Equatable {
        /// Paused: the controls show.
        case adjusted
        /// Resumed after a pause: the controls go away at once.
        case resumed
    }

    let kind: Kind
    /// Increases with every activity, so repeating the same kind still registers.
    let count: Int
}
#endif
